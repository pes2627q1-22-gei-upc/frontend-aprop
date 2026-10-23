import '../models/user_profile.dart';

/// Manté l'usuari de la base de dades d'AProp! sincronitzat amb el compte de
/// Firebase de la sessió.
///
/// Les operacions llancen `AuthFailure` quan l'error es pot explicar a
/// l'usuari.
abstract interface class UserSyncRepository {
  /// Retorna el perfil de l'usuari de la sessió. El primer cop el crea amb
  /// [username]; després [username] s'ignora.
  ///
  /// Retorna `null` si l'usuari encara no existeix i no s'ha passat cap
  /// [username] (cal que en triï un). Llança `AuthFailure.usernameAlreadyInUse`
  /// si el nom ja és d'una altra persona.
  Future<UserProfile?> sync({String? username});
}
