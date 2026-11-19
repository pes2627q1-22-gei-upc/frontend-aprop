import '../../../core/network/api_client.dart';
import '../models/profile_settings.dart';
import '../repositories/profile_settings_repository.dart';
import 'profile_api.dart';

class HttpProfileSettingsRepository implements ProfileSettingsRepository {
  HttpProfileSettingsRepository({required this.apiClient})
    : _profiles = ProfileApi(apiClient);
  final ApiClient apiClient;
  final ProfileApi _profiles;

  @override
  Set<ProfilePreference> get supportedPreferences => const {
    ProfilePreference.showMyPlans,
  };
  @override
  bool get persistsPreferences => true;

  ProfileSettings _settings(Map<String, Object?> json) {
    if (json['show-plans'] case final bool visible) {
      return ProfileSettings(showMyPlans: visible);
    }
    throw const FormatException('Expected show-plans setting');
  }

  @override
  Future<ProfileSettings> getSettings(String userId) async =>
      _settings((await _profiles.own(userId)).profile);

  @override
  Future<void> updateLanguage({
    required String userId,
    required String language,
  }) async {
    // TODO(DP-054): `language` in PATCH /users/me is the agreed backend
    // contract for #28; the response is not read back yet.
    final session = await _profiles.own(userId);
    await apiClient.patchJson(
      'users/me',
      headers: session.headers,
      body: {'language': language},
    );
  }

  @override
  Future<ProfileSettings> updatePreference({
    required String userId,
    required ProfilePreference preference,
    required bool enabled,
  }) async {
    // TODO(DP-040): Only show-plans exists in PATCH /users/me. Never pretend
    // that a notification toggle was saved by storing it in a local map.
    if (!supportedPreferences.contains(preference)) {
      throw UnsupportedError('Preference has no server endpoint');
    }
    final session = await _profiles.own(userId);
    final decoded = await apiClient.patchJson(
      'users/me',
      headers: session.headers,
      body: {'show-plans': enabled},
    );
    return _settings(validateOwnProfile(decoded, userId));
  }
}
