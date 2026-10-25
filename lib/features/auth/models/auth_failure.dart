/// Errors d'autenticació que la interfície sap explicar a l'usuari.
///
/// Cada implementació del repositori tradueix els seus errors (Firebase,
/// backend...) a aquests valors.
enum AuthFailure implements Exception {
  invalidCredentials,
  emailAlreadyInUse,
  usernameAlreadyInUse,
  network,

  /// S'han fet massa intents seguits i el servei bloqueja l'operació una estona.
  tooManyRequests,

  /// El servei només deixa entrar amb el correu, no amb el nom d'usuari.
  emailRequired,

  /// El navegador ha bloquejat la finestra emergent de Google (només web).
  popupBlocked,
}
