import 'dart:async';

import '../models/app_user.dart';
import '../models/auth_failure.dart';
import '../repositories/auth_repository.dart';

/// Comptes en memòria mentre no tenim Firebase ni l'alta al backend.
/// Es perden en tancar l'aplicació.
class DemoAuthRepository implements AuthRepository {
  final Map<String, _DemoAccount> _accounts = {
    'laia@aprop.cat': const _DemoAccount(
      password: 'Aprop2026!',
      user: AppUser(
        id: 'demo-laiasoler',
        email: 'laia@aprop.cat',
        firstName: 'Laia',
        lastName: 'Soler',
        username: 'laiasoler',
      ),
    ),
  };
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
      username: username,
    );
    _accounts[key] = _DemoAccount(password: password, user: user);
    _setCurrentUser(user);
  }

  @override
  Future<void> signOut() async {
    _setCurrentUser(null);
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
