import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/auth_failure.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_sync_repository.dart';
import 'firebase_auth_failure.dart';

/// Comptes reals amb Firebase Auth: correu i contrasenya, i Google (a
/// Android amb el selector del sistema i a la web amb una finestra emergent).
///
/// El nom d'usuari és al backend ([UserSyncRepository]). El nom i els cognoms
/// van provisionalment al `displayName` de Firebase, fins que el backend els
/// desi (DP-026).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required this._userSync,
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    SharedPreferencesAsync? preferences,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _preferences = preferences ?? SharedPreferencesAsync();

  /// Idioma dels correus que envia Firebase (verificació del compte).
  static const _emailLanguage = 'ca';

  final UserSyncRepository _userSync;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Còpia de l'últim nom d'usuari conegut, per si el backend no respon.
  final SharedPreferencesAsync _preferences;

  /// Noms d'usuari ja consultats en aquesta sessió, per no preguntar-los al
  /// backend cada vegada que Firebase avisa d'un canvi (com renovar el token).
  final Map<String, String> _usernames = {};

  /// Avisa que l'usuari ha canviat sense que Firebase ho emeti: el nom
  /// d'usuari desat al dispositiu o la verificació del correu en recarregar.
  final StreamController<void> _localChanges = StreamController.broadcast();
  Future<void>? _googleInitialization;

  @override
  Stream<AppUser?> authStateChanges() {
    late final StreamController<User?> changes;
    StreamSubscription<User?>? firebaseChanges;
    StreamSubscription<void>? localChanges;

    changes = StreamController<User?>(
      onListen: () {
        firebaseChanges = _auth.userChanges().listen(
          changes.add,
          onError: changes.addError,
        );
        localChanges = _localChanges.stream.listen(
          (_) => changes.add(_auth.currentUser),
        );
      },
      onCancel: () async {
        await firebaseChanges?.cancel();
        await localChanges?.cancel();
      },
    );

    // `asyncMap` respecta l'ordre: un canvi antic no pot arribar després d'un
    // de més nou encara que trigui més a llegir el nom d'usuari.
    return changes.stream.asyncMap(_toAppUser);
  }

  @override
  Future<void> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    // TODO(DP-026): entrar amb el nom d'usuari depèn d'un endpoint del backend.
    if (!usernameOrEmail.contains('@')) throw AuthFailure.emailRequired;

    await _run(
      () => _auth.signInWithEmailAndPassword(
        email: usernameOrEmail,
        password: password,
      ),
      failureFromCode: signInFailureFromFirebaseCode,
    );
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    final credential = await _run(
      () => _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
    final user = credential.user!;

    // A partir d'aquí el compte ja existeix i AuthGate ja mostra la
    // verificació del correu. Si un pas posterior fallés i es mostrés l'error,
    // tornar a enviar el formulari diria «ja hi ha un compte amb aquest
    // correu». Per això no s'aturen: el correu es pot reenviar des de la
    // pantalla de verificació.
    // Si el nom d'usuari ja és d'algú altre, l'usuari en triarà un altre
    // després de verificar el correu, i la pantalla li explicarà per què.
    await _ignoreFailure(() => user.updateDisplayName('$firstName $lastName'));
    await _ignoreFailure(() async {
      try {
        await _syncUsername(user.uid, username);
      } on AuthFailure catch (failure) {
        if (failure != AuthFailure.usernameAlreadyInUse) rethrow;
        await _preferences.setString(_rejectedUsernameKey(user.uid), username);
      }
    });
    await _ignoreFailure(() => _sendEmailVerification(user));
    _localChanges.add(null);
  }

  @override
  Future<bool> signInWithGoogle() async {
    if (kIsWeb) return _signInWithGooglePopup();

    await _initializeGoogle();

    final GoogleSignInAccount account;
    try {
      // Obre el selector de comptes del sistema.
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google no ha retornat el token del compte.');
    }

    await _run(
      () => _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      ),
    );
    return true;
  }

  /// A la web, Firebase obre la finestra emergent de Google. S'ha de cridar
  /// sense cap `await` abans: si no, el navegador no la considera una acció
  /// de l'usuari i la bloqueja.
  Future<bool> _signInWithGooglePopup() async {
    try {
      await _auth.signInWithPopup(GoogleAuthProvider());
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return false;
      }
      throw authFailureFromFirebaseCode(e.code) ?? e;
    }
  }

  @override
  Future<void> chooseUsername(String username) async {
    await _syncUsername(_requireCurrentUser().uid, username);
    _localChanges.add(null);
  }

  @override
  Future<void> sendEmailVerification() {
    return _run(() => _sendEmailVerification(_requireCurrentUser()));
  }

  /// Els enllaços dels correus porten una clau d'API antiga que ja no és
  /// vàlida, i la pàgina de Firebase que els obre falla («ha caducat»). Amb
  /// l'enllaç enganxat a l'app, el codi es confirma amb la clau de l'app.
  // TODO(DP-031): sobrarà si Firebase torna a associar una clau vàlida als
  // correus.
  @override
  Future<void> verifyEmailWithLink(String link) async {
    final code = verificationCodeFromLink(link);
    if (code == null) throw AuthFailure.invalidVerificationLink;

    await _run(() => _auth.applyActionCode(code));
    await _run(_requireCurrentUser().reload);

    // Un enllaç d'un altre compte s'aplica a aquell compte, no a aquest.
    if (!(_auth.currentUser?.emailVerified ?? false)) {
      throw AuthFailure.invalidVerificationLink;
    }
    _localChanges.add(null);
  }

  @override
  Future<bool> checkEmailVerified() async {
    await _run(_requireCurrentUser().reload);

    final verified = _auth.currentUser?.emailVerified ?? false;
    // Recarregar no sempre fa emetre `userChanges`: ho forcem perquè
    // AuthGate deixi passar l'usuari.
    if (verified) _localChanges.add(null);
    return verified;
  }

  @override
  Future<void> signOut() async {
    try {
      // També es tanca la sessió de Google perquè la propera vegada es pugui
      // triar un altre compte. A la web la porta Firebase.
      if (!kIsWeb) {
        await _initializeGoogle();
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Si Google falla, la sessió de l'app s'ha de tancar igualment.
    } finally {
      _usernames.clear();
      await _auth.signOut();
    }
  }

  Future<void> _sendEmailVerification(User user) async {
    await _auth.setLanguageCode(_emailLanguage);
    await user.sendEmailVerification();
  }

  /// El paquet de Google s'ha d'inicialitzar una sola vegada. L'identificador
  /// del client web el llegeix de `google-services.json`. Si falla, es torna a
  /// provar la vegada següent.
  Future<void> _initializeGoogle() {
    return _googleInitialization ??= _googleSignIn.initialize().catchError((
      Object error,
    ) {
      _googleInitialization = null;
      throw error;
    });
  }

  Future<AppUser?> _toAppUser(User? user) async {
    if (user == null) return null;

    final (firstName, lastName) = splitDisplayName(user.displayName);
    final username = await _usernameFor(user.uid);
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      firstName: firstName,
      lastName: lastName,
      emailVerified: user.emailVerified,
      username: username,
      rejectedUsername: username == null
          ? await _preferences.getString(_rejectedUsernameKey(user.uid))
          : null,
    );
  }

  /// Nom d'usuari del backend, o `null` si encara no en té cap.
  Future<String?> _usernameFor(String uid) async {
    final known = _usernames[uid];
    if (known != null) return known;

    try {
      final profile = await _userSync.sync();
      return profile == null ? null : await _remember(uid, profile.username);
    } catch (error) {
      // Sense connexió no es demana un nom nou: es fa servir l'últim conegut.
      debugPrint("Auth: no s'ha pogut consultar l'usuari: $error");
      return _preferences.getString(_cachedUsernameKey(uid));
    }
  }

  /// Crea l'usuari al backend amb [username]. Si ja existia, el backend en
  /// conserva el nom original.
  Future<void> _syncUsername(String uid, String username) async {
    final profile = await _userSync.sync(username: username);
    if (profile == null) {
      throw StateError('El backend no ha retornat cap usuari.');
    }
    await _remember(uid, profile.username);
  }

  Future<String> _remember(String uid, String username) async {
    _usernames[uid] = username;
    await _preferences.setString(_cachedUsernameKey(uid), username);
    // Ja té nom: l'avís del nom rebutjat deixa de tenir sentit.
    await _preferences.remove(_rejectedUsernameKey(uid));
    return username;
  }

  String _cachedUsernameKey(String uid) => 'auth.cachedUsername.$uid';

  /// Es desa al dispositiu perquè l'avís sobrevisqui si l'app es tanca abans
  /// de verificar el correu.
  String _rejectedUsernameKey(String uid) => 'auth.rejectedUsername.$uid';

  User _requireCurrentUser() {
    return _auth.currentUser ??
        (throw StateError('No hi ha cap sessió iniciada.'));
  }

  /// Executa una operació de Firebase i en tradueix els errors coneguts.
  Future<T> _run<T>(
    Future<T> Function() operation, {
    AuthFailure? Function(String code) failureFromCode =
        authFailureFromFirebaseCode,
  }) async {
    try {
      return await operation();
    } on FirebaseAuthException catch (e) {
      throw failureFromCode(e.code) ?? e;
    }
  }

  Future<void> _ignoreFailure(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error) {
      debugPrint('Auth: pas opcional del registre fallit: $error');
    }
  }
}
