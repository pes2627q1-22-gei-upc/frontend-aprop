import '../../../core/network/api_client.dart';
import '../models/profile_settings.dart';
import '../models/notification_preferences.dart';
import '../repositories/profile_settings_repository.dart';
import 'profile_api.dart';
import 'notification_preferences_payload.dart';

class HttpProfileSettingsRepository implements ProfileSettingsRepository {
  HttpProfileSettingsRepository({required this.apiClient})
    : _profiles = ProfileApi(apiClient);
  final ApiClient apiClient;
  final ProfileApi _profiles;

  @override
  Set<ProfilePreference> get supportedPreferences => const {
    ProfilePreference.showMyPlans,
    ...NotificationPreferences.types,
  };
  @override
  bool get persistsPreferences => true;

  static const _supportedLanguages = {'ca', 'es', 'en'};

  ProfileSettings _settings(Map<String, Object?> json) {
    if (json['show-plans'] case final bool visible) {
      final rawLanguage = json['language'];
      final normalized = rawLanguage is String
          ? rawLanguage.trim().toLowerCase()
          : null;
      final language =
          normalized != null && _supportedLanguages.contains(normalized)
          ? normalized
          : null;
      return ProfileSettings(showMyPlans: visible, language: language);
    }
    throw const FormatException('Expected show-plans setting');
  }

  @override
  Future<ProfileSettings> getSettings(String userId) async =>
      _settings((await _profiles.own(userId)).profile);

  Future<
    ({
      NotificationPreferencesPayload settings,
      Map<ProfilePreference, int> types,
    })
  >
  _notificationSettings(Map<String, String> headers) async {
    final values = await Future.wait([
      apiClient.getJson('users/me/settings', headers: headers),
      apiClient.getJson('notificationtypes', headers: headers),
    ]);
    return (
      settings: NotificationPreferencesPayload.fromJson(values[0]),
      types: notificationPreferenceTypes(values[1]),
    );
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences(
    String userId,
  ) async {
    final session = await _profiles.own(userId);
    final result = await _notificationSettings(session.headers);
    return result.settings.preferences(result.types);
  }

  @override
  Future<NotificationPreferences> updateNotificationPreference({
    required String userId,
    required ProfilePreference preference,
    required bool enabled,
  }) async {
    if (!NotificationPreferences.types.contains(preference)) {
      throw UnsupportedError('Not a notification preference');
    }
    final session = await _profiles.own(userId);
    // Read the complete set immediately before changing one type. Unknown or
    // future IDs belong to the server and must not be removed by this client.
    final current = await _notificationSettings(session.headers);
    final id = current.types[preference];
    if (id == null) throw UnsupportedError('Unavailable notification type');
    final allowed = {...current.settings.allowedIds};
    if (enabled) {
      allowed.add(id);
    } else {
      allowed.remove(id);
    }
    final sorted = allowed.toList()..sort();
    final decoded = await apiClient.patchJson(
      'users/me',
      headers: session.headers,
      body: {'allowed-notif-types': sorted},
    );
    final profile = validateOwnProfile(decoded, userId);
    if ((profile['id'] as String).toLowerCase() !=
        (session.profile['id'] as String).toLowerCase()) {
      throw const FormatException('The updated account changed');
    }
    // PATCH returns UserProfile, which has no allowed-notif-types. Only the
    // authenticated Settings read-back can confirm that the change was saved.
    // TODO(DP-084): backend 4f98835 can skip this write when Language is set.
    // Keep read-back confirmation; never turn a 200 into a fictitious success.
    final confirmed = NotificationPreferencesPayload.fromJson(
      await apiClient.getJson('users/me/settings', headers: session.headers),
    );
    if (confirmed.settingsId != current.settings.settingsId ||
        confirmed.allowedIds.length != allowed.length ||
        !confirmed.allowedIds.containsAll(allowed)) {
      throw const FormatException(
        'Notification preferences were not confirmed',
      );
    }
    return confirmed.preferences(current.types);
  }

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
    if (preference != ProfilePreference.showMyPlans) {
      throw UnsupportedError(
        'Use updateNotificationPreference for delivery settings',
      );
    }
    final session = await _profiles.own(userId);
    final decoded = await apiClient.patchJson(
      'users/me',
      headers: session.headers,
      body: {'show-plans': enabled},
    );
    final profile = validateOwnProfile(decoded, userId);
    if ((profile['id'] as String).toLowerCase() !=
        (session.profile['id'] as String).toLowerCase()) {
      throw const FormatException(
        'The updated profile belongs to another account',
      );
    }
    final confirmed = _settings(profile);
    if (confirmed.showMyPlans != enabled) {
      throw const FormatException(
        'The requested privacy setting was not saved',
      );
    }
    return confirmed;
  }
}
