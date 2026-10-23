/// Perfil de l'usuari a la base de dades d'AProp!, vinculat al compte de
/// Firebase.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
  });

  final String id;
  final String username;
  final String email;
}
