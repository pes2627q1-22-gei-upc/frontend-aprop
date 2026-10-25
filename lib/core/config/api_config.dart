/// Adreça del backend d'AProp!.
///
/// Es passa en executar o compilar l'app, sense canviar el codi:
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
/// ```
///
/// Si és buida, l'app fa servir dades de demostració.
// TODO(DP-028): URL del servidor desplegat quan existeixi.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get isConfigured => baseUrl.isNotEmpty;
}
