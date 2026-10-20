import 'dart:async';

import '../models/app_user.dart';
import '../models/auth_failure.dart';
import '../repositories/auth_repository.dart';

/// Comptes en memòria mentre no tenim Firebase ni l'alta al backend.
/// Es perden en tancar l'aplicació.
///
/// No s'envia cap correu de veritat: la comprovació simula que l'usuari ha
/// obert l'enllaç i dona el correu per verificat si abans se n'ha «enviat» un.
class DemoAuthRepository implements AuthRepository {
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
  Future<void> sendEmailVerification() async {
    _verificationEmailsSent.add(_requireCurrentUser().email);
  }

  @override
  Future<bool> checkEmailVerified() async {
    final user = _requireCurrentUser();

    if (user.emailVerified) return true;
    if (!_verificationEmailsSent.contains(user.email)) return false;

    final account = _accounts[user.email]!;
    final verifiedUser = AppUser(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      emailVerified: true,
      username: user.username,
    );
    _accounts[user.email] = _DemoAccount(
      password: account.password,
      user: verifiedUser,
    );
    _setCurrentUser(verifiedUser);
    return true;
  }

  @override
  Future<void> signOut() async {
    _setCurrentUser(null);
  }

  AppUser _requireCurrentUser() {
    return _currentUser ?? (throw StateError('No hi ha cap sessió iniciada.'));
  }

  void _setCurrentUser(AppUser? user) {
    _currentUser = user;
    _changes.add(user);
  }
}

class _DemoAccount {
  const _DemoAccount({required this.password, required this.user});

  final String password;
  final AppUser user;
}
