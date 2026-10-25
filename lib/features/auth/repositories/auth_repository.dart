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

  /// Crea el compte, dona d'alta l'usuari al backend, inicia la sessió i envia
  /// el correu de verificació.
  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  });

  /// Torna a enviar el correu de verificació a l'usuari de la sessió.
  Future<void> sendEmailVerification();

  /// Torna a consultar si l'usuari de la sessió ha verificat el correu.
  /// Retorna `true` si ja l'ha verificat; llavors el canvi també arriba per
  /// [authStateChanges].
  Future<bool> checkEmailVerified();

  Future<void> signOut();

  /// Token de la sessió per identificar l'usuari davant del backend
  /// (`Authorization: Bearer`). És nul si no hi ha sessió o si les dades són
  /// de demostració.
  Future<String?> currentIdToken();
}
