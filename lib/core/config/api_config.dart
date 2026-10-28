/// Configuració global de connexió amb el backend d'AProp! a Render.
///
/// Per defecte apunta al servei desplegat a Render (`https://api-aprop.onrender.com`).
/// Es pot sobreescriure en executar o compilar l'app amb `--dart-define`:
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
/// ```
abstract final class ApiConfig {
  static const String defaultBaseUrl = 'https://api-aprop.onrender.com';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  /// Timeout d'almenys 60 segons per absorbir el cold start de Render Free
  /// (que pot trigar entre 30 i 55 segons quan el contenidor està adormit).
  static const Duration connectTimeout = Duration(seconds: 60);

  static bool get isConfigured => baseUrl.isNotEmpty;
}
