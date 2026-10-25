/// Perfil de l'usuari a la base de dades d'AProp!, vinculat al compte de
/// Firebase.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.name = '',
  });

  final String id;
  final String username;
  final String email;

  /// Nom i cognoms, en un sol camp. Buit si encara no s'ha desat.
  final String name;
}
