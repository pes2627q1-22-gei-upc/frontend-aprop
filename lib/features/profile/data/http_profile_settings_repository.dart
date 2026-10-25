import '../../../core/network/api_client.dart';
import '../models/profile_settings.dart';
import '../repositories/profile_settings_repository.dart';

/// Implementació de [ProfileSettingsRepository] connectada al backend de Render
/// (`GET /users/me` i `PATCH /users/me` per a `show-plans`).
class HttpProfileSettingsRepository implements ProfileSettingsRepository {
  HttpProfileSettingsRepository({required this.apiClient});

  final ApiClient apiClient;
  final Map<String, ProfileSettings> _settings = {};

  @override
  Future<ProfileSettings> getSettings(String userId) async {
    final current = _settings[userId] ?? const ProfileSettings();
    try {
      final decoded = await apiClient.getJson('users/me');
      if (decoded is Map<String, Object?>) {
        final showPlans =
            decoded['show-plans'] as bool? ??
            decoded['plans-visible'] as bool? ??
            current.showMyPlans;
        final updated = current.withPreference(
          ProfilePreference.showMyPlans,
          showPlans,
        );
        _settings[userId] = updated;
        return updated;
      }
    } on ApiException {
      // Si el perfil encara no existeix al backend, retorna les preferències locals.
    }
    return current;
  }

  @override
  Future<ProfileSettings> updatePreference({
    required String userId,
    required ProfilePreference preference,
    required bool enabled,
  }) async {
    if (preference == ProfilePreference.showMyPlans) {
      await apiClient.patchJson(
        'users/me',
        body: <String, Object?>{'show-plans': enabled},
      );
    }
    final current = _settings[userId] ?? const ProfileSettings();
    final updated = current.withPreference(preference, enabled);
    _settings[userId] = updated;
    return updated;
  }
}
