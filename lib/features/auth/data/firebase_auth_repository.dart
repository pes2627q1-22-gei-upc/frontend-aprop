import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/auth_failure.dart';
import '../models/user_profile.dart';
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

  /// Perfils ja consultats en aquesta sessió, per no preguntar-los al backend
  /// cada vegada que Firebase avisa d'un canvi (com renovar el token).
  final Map<String, UserProfile> _profiles = {};

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
        await _saveName(user.uid, '$firstName $lastName');
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
    final user = _requireCurrentUser();
    final profile = await _syncUsername(user.uid, username);
    // Primer accés amb Google (o nom rebutjat en registrar-se): el backend
    // encara no té el nom, i el de Firebase és el bo.
    if (profile.name.isEmpty) {
      await _ignoreFailure(() => _saveName(user.uid, user.displayName ?? ''));
    }
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
  Future<void> confirmEmailVerification(String code) async {
    await _run(() => _auth.applyActionCode(code));

    // Si aquesta web ja tenia la sessió del compte, entra sense més passos.
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.reload();
      _localChanges.add(null);
    } catch (error) {
      // El correu ja està verificat: l'app ho veurà en tornar-ho a consultar.
      debugPrint("Auth: no s'ha pogut actualitzar la sessió: $error");
    }
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

  /// Firebase el renova sol quan està a punt de caducar (dura una hora).
  @override
  Future<String?> currentIdToken() async => _auth.currentUser?.getIdToken();

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
      _profiles.clear();
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

    final profile = await _profileFor(user);
    final username = profile?.username;
    // El nom del backend mana; mentre no en té, el de Firebase.
    final name = profile?.name ?? '';
    final (firstName, lastName) = splitDisplayName(
      name.isNotEmpty ? name : user.displayName,
    );
    final serverId = profile?.id ?? '';
    return AppUser(
      id: user.uid,
      serverId: serverId.isEmpty ? null : serverId,
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

  /// Perfil del backend, o `null` si encara no té nom d'usuari.
  Future<UserProfile?> _profileFor(User user) async {
    final uid = user.uid;
    final known = _profiles[uid];
    if (known != null) return known;

    try {
      final profile = await _userSync.sync();
      if (profile == null) return null;
      await _remember(uid, profile);
      // Si en registrar-se no es va poder desar el nom, es torna a provar.
      if (profile.name.isEmpty) {
        await _ignoreFailure(() => _saveName(uid, user.displayName ?? ''));
      }
      return _profiles[uid];
    } catch (error) {
      // Sense connexió no es demana un nom nou: es fa servir l'últim conegut.
      debugPrint("Auth: no s'ha pogut consultar l'usuari: $error");
      final username = await _preferences.getString(_cachedUsernameKey(uid));
      if (username == null) return null;
      return UserProfile(
        id: await _preferences.getString(_cachedServerIdKey(uid)) ?? '',
        username: username,
        email: '',
        name: await _preferences.getString(_cachedNameKey(uid)) ?? '',
      );
    }
  }

  /// Crea l'usuari al backend amb [username]. Si ja existia, el backend en
  /// conserva el nom original.
  Future<UserProfile> _syncUsername(String uid, String username) async {
    final profile = await _userSync.sync(username: username);
    if (profile == null) {
      throw StateError('El backend no ha retornat cap usuari.');
    }
    return _remember(uid, profile);
  }

  /// Desa el nom i cognoms al backend (`PATCH /users/me`).
  // TODO(DP-026): el backend només té un camp «name», sense separar el nom
  // dels cognoms.
  Future<void> _saveName(String uid, String name) async {
    if (name.trim().isEmpty) return;
    await _remember(uid, await _userSync.updateName(name.trim()));
  }

  Future<UserProfile> _remember(String uid, UserProfile received) async {
    // Si una resposta no porta l'identificador, es conserva el que ja se sabia.
    final knownId = _profiles[uid]?.id ?? '';
    final profile = received.id.isNotEmpty || knownId.isEmpty
        ? received
        : UserProfile(
            id: knownId,
            username: received.username,
            email: received.email,
            name: received.name,
          );
    _profiles[uid] = profile;
    await _preferences.setString(_cachedUsernameKey(uid), profile.username);
    await _preferences.setString(_cachedNameKey(uid), profile.name);
    if (profile.id.isNotEmpty) {
      await _preferences.setString(_cachedServerIdKey(uid), profile.id);
    }
    // Ja té nom: l'avís del nom rebutjat deixa de tenir sentit.
    await _preferences.remove(_rejectedUsernameKey(uid));
    return profile;
  }

  String _cachedUsernameKey(String uid) => 'auth.cachedUsername.$uid';

  String _cachedNameKey(String uid) => 'auth.cachedName.$uid';

  String _cachedServerIdKey(String uid) => 'auth.cachedServerId.$uid';

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
