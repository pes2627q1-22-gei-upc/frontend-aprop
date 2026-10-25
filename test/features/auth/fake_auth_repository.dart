import 'dart:async';

import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/auth/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  /// Si no és nul, les operacions el llancen.
  Object? error;

  /// Si no és nul, les operacions esperen que es completi.
  Completer<void>? pending;

  Map<String, String>? lastCall;

  /// Resposta de [checkEmailVerified].
  bool emailVerified = false;

  int verificationEmailsSent = 0;

  /// Resposta de [signInWithGoogle]: `false` simula que l'usuari tanca el
  /// selector de comptes.
  bool googleAccountChosen = true;

  int googleSignIns = 0;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(null);

  @override
  Future<void> signIn({
    required String usernameOrEmail,
    required String password,
  }) {
    lastCall = {'usernameOrEmail': usernameOrEmail, 'password': password};
    return _respond();
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) {
    lastCall = {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'password': password,
    };
    return _respond();
  }

  @override
  Future<bool> signInWithGoogle() async {
    googleSignIns++;
    await _respond();
    return googleAccountChosen;
  }

  @override
  Future<void> chooseUsername(String username) {
    lastCall = {'username': username};
    return _respond();
  }

  @override
  Future<void> sendEmailVerification() async {
    await _respond();
    verificationEmailsSent++;
  }

  @override
  Future<void> verifyEmailWithLink(String link) {
    lastCall = {'link': link};
    return _respond();
  }

  @override
  Future<bool> checkEmailVerified() async {
    await _respond();
    return emailVerified;
  }

  @override
  Future<void> signOut() => _respond();

  /// Resposta de [currentIdToken].
  String? idToken;

  @override
  Future<String?> currentIdToken() async => idToken;

  Future<void> _respond() async {
    await pending?.future;
    if (error case final error?) throw error;
  }
}
