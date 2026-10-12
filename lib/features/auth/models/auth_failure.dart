/// Errors d'autenticació que la interfície sap explicar a l'usuari.
///
/// Cada implementació del repositori tradueix els seus errors (Firebase,
/// backend...) a aquests valors.
enum AuthFailure implements Exception {
  invalidCredentials,
  emailAlreadyInUse,
  usernameAlreadyInUse,
  network,
}
