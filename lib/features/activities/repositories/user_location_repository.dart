import '../models/user_position.dart';

/// Si l'app pot saber on és la persona.
enum LocationAccess {
  granted,

  /// No hi ha permís, però encara es pot demanar.
  denied,

  /// La persona l'ha denegat i ja no es pot tornar a demanar: només es pot
  /// donar des de la configuració del mòbil o del navegador.
  deniedForever,

  /// El dispositiu té la ubicació desactivada.
  serviceDisabled,
}

/// Ubicació del dispositiu i permís per fer-la servir.
abstract interface class UserLocationRepository {
  /// Estat del permís, sense preguntar res a la persona.
  Future<LocationAccess> checkAccess();

  /// Demana el permís si encara es pot (diàleg del sistema o del navegador).
  Future<LocationAccess> requestAccess();

  /// Posicions mentre s'escolta. Només amb el permís donat.
  Stream<UserPosition> watchPosition();

  /// Fals a la web: el permís es canvia des del navegador.
  bool get canOpenSettings;

  /// Configuració de l'app, per donar el permís denegat per sempre.
  Future<void> openAppSettings();

  /// Configuració d'ubicació del dispositiu, per activar-la.
  Future<void> openLocationSettings();
}
