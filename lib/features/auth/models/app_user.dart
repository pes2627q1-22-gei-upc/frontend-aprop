class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.emailVerified,
    this.username,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;

  /// Fins que no és `true`, l'usuari no pot entrar a l'aplicació.
  final bool emailVerified;

  /// És nul fins que l'usuari tria nom d'usuari (primer accés amb Google).
  final String? username;

  AppUser copyWith({bool? emailVerified, String? username}) {
    return AppUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      emailVerified: emailVerified ?? this.emailVerified,
      username: username ?? this.username,
    );
  }
}
