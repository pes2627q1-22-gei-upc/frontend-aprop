class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.username,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;

  /// És nul fins que l'usuari tria nom d'usuari (primer accés amb Google).
  final String? username;
}
