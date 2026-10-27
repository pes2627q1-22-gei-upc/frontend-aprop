class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.emailVerified,
    this.username,
    this.rejectedUsername,
    this.serverId,
  });

  /// Identificador del compte a l'app (l'UID de Firebase o el de
  /// demostració).
  final String id;

  /// Identificador de l'usuari a la base de dades del backend (l'UUID de
  /// `users`), que el backend fa servir a inscripcions i agenda. És nul amb
  /// dades de demostració o si encara no s'ha pogut consultar el backend.
  final String? serverId;
  final String email;
  final String firstName;
  final String lastName;

  /// Fins que no és `true`, l'usuari no pot entrar a l'aplicació.
  final bool emailVerified;

  /// És nul fins que l'usuari tria nom d'usuari (primer accés amb Google).
  final String? username;

  /// Nom d'usuari que es va demanar en registrar-se i que ja era d'una altra
  /// persona. Mentre [username] és nul, explica per què se'n demana un altre.
  final String? rejectedUsername;

  /// Nom i cognoms sense espais sobrants: un compte de Google pot no tenir
  /// cognoms.
  String get fullName => '$firstName $lastName'.trim();

  AppUser copyWith({bool? emailVerified, String? username}) {
    return AppUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      emailVerified: emailVerified ?? this.emailVerified,
      username: username ?? this.username,
      serverId: serverId,
    );
  }
}
