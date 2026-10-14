import '../models/app_user.dart';

/// Les operacions llancen [AuthFailure] quan l'error es pot explicar a
/// l'usuari. Quan una operació acaba bé, el canvi de sessió arriba per
/// [authStateChanges].
abstract interface class AuthRepository {
  /// Emet l'usuari actual en subscriure-s'hi i cada vegada que canvia la
  /// sessió. `null` vol dir que no hi ha cap sessió iniciada.
  Stream<AppUser?> authStateChanges();

  /// [usernameOrEmail] pot ser el nom d'usuari o el correu del compte.
  Future<void> signIn({
    required String usernameOrEmail,
    required String password,
  });

  /// Crea el compte, dona d'alta l'usuari al backend i inicia la sessió.
  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
