import 'dart:async';

import '../models/app_user.dart';
import '../models/auth_failure.dart';
import '../repositories/auth_repository.dart';

/// Comptes en memòria mentre no tenim Firebase ni l'alta al backend.
/// Es perden en tancar l'aplicació.
///
/// No s'envia cap correu de veritat: la comprovació simula que l'usuari ha
/// obert l'enllaç i dona el correu per verificat si abans se n'ha «enviat» un.
///
/// Tampoc no s'obre el selector de Google: sempre «es tria» el mateix compte,
/// que el primer cop no té nom d'usuari.
class DemoAuthRepository implements AuthRepository {
  static const _googleUser = AppUser(
    id: 'demo-google-jordipuig',
    email: 'jordi.puig@gmail.com',
    firstName: 'Jordi',
    lastName: 'Puig',
    // Google ja ha verificat el correu del compte.
    emailVerified: true,
  );

  final Map<String, _DemoAccount> _accounts = {
    'laia@aprop.cat': const _DemoAccount(
      password: 'Aprop2026!',
      user: AppUser(
        id: 'demo-laiasoler',
        email: 'laia@aprop.cat',
        firstName: 'Laia',
        lastName: 'Soler',
        emailVerified: true,
        username: 'laiasoler',
      ),
    ),
  };
  final Set<String> _verificationEmailsSent = {};
  final StreamController<AppUser?> _changes = StreamController.broadcast();
  AppUser? _currentUser;

  @override
  Stream<AppUser?> authStateChanges() {
    late final StreamController<AppUser?> controller;
    StreamSubscription<AppUser?>? changes;

    controller = StreamController<AppUser?>(
      onListen: () {
        controller.add(_currentUser);
        changes = _changes.stream.listen(controller.add);
      },
      onCancel: () => changes?.cancel(),
    );

    return controller.stream;
  }

  @override
  Future<void> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    final key = usernameOrEmail.toLowerCase();
    final account =
        _accounts[key] ??
        _accounts.values.where((a) => a.user.username == key).firstOrNull;

    if (account == null || account.password != password) {
      throw AuthFailure.invalidCredentials;
    }

    _setCurrentUser(account.user);
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    final key = email.toLowerCase();

    if (_accounts.containsKey(key)) {
      throw AuthFailure.emailAlreadyInUse;
    }
    if (_accounts.values.any((account) => account.user.username == username)) {
      throw AuthFailure.usernameAlreadyInUse;
    }

    final user = AppUser(
      id: 'demo-$username',
      email: key,
      firstName: firstName,
      lastName: lastName,
      emailVerified: false,
      username: username,
    );
    _accounts[key] = _DemoAccount(password: password, user: user);
    _verificationEmailsSent.add(key);
    _setCurrentUser(user);
  }

  @override
  Future<bool> signInWithGoogle() async {
    final account = _accounts.putIfAbsent(
      _googleUser.email,
      () => const _DemoAccount(user: _googleUser),
    );
    _setCurrentUser(account.user);
    return true;
  }

  // TODO(DP-025): el nom d'usuari s'haurà de desar al backend.
  @override
  Future<void> chooseUsername(String username) async {
    final user = _requireCurrentUser();

    if (_accounts.values.any((account) => account.user.username == username)) {
      throw AuthFailure.usernameAlreadyInUse;
    }

    _updateCurrentUser(user.copyWith(username: username));
  }

  @override
  Future<void> sendEmailVerification() async {
    _verificationEmailsSent.add(_requireCurrentUser().email);
  }

  /// Simula l'enllaç del correu: n'hi ha prou que porti un codi (`oobCode`).
  @override
  Future<void> verifyEmailWithLink(String link) async {
    if (!link.contains('oobCode=')) throw AuthFailure.invalidVerificationLink;
    final user = _requireCurrentUser();
    _updateCurrentUser(user.copyWith(emailVerified: true));
  }

  /// Simula el codi de l'enllaç obert a la web: n'hi ha prou que no sigui buit.
  @override
  Future<void> confirmEmailVerification(String code) async {
    if (code.trim().isEmpty) throw AuthFailure.invalidVerificationLink;
    final user = _currentUser;
    if (user != null) _updateCurrentUser(user.copyWith(emailVerified: true));
  }

  @override
  Future<bool> checkEmailVerified() async {
    final user = _requireCurrentUser();

    if (user.emailVerified) return true;
    if (!_verificationEmailsSent.contains(user.email)) return false;

    _updateCurrentUser(user.copyWith(emailVerified: true));
    return true;
  }

  /// Els comptes de demostració no tenen token: el backend no els coneix.
  @override
  Future<String?> currentIdToken() async => null;

  @override
  Future<void> signOut() async {
    _setCurrentUser(null);
  }

  AppUser _requireCurrentUser() {
    return _currentUser ?? (throw StateError('No hi ha cap sessió iniciada.'));
  }

  /// Desa els canvis al compte perquè es conservin en tornar a entrar.
  void _updateCurrentUser(AppUser user) {
    final account = _accounts[user.email]!;
    _accounts[user.email] = _DemoAccount(
      password: account.password,
      user: user,
    );
    _setCurrentUser(user);
  }

  void _setCurrentUser(AppUser? user) {
    _currentUser = user;
    _changes.add(user);
  }
}

class _DemoAccount {
  const _DemoAccount({this.password, required this.user});

  /// És nul als comptes de Google: només s'hi pot entrar amb Google.
  final String? password;
  final AppUser user;
}
