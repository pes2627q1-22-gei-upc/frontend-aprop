import '../models/profile_settings.dart';
import '../repositories/profile_settings_repository.dart';

/// Per-account preferences, retained through sign-out during this app run only.
// TODO(DP-033): Integrate privacy enforcement and notification delivery settings.
class DemoProfileSettingsRepository implements ProfileSettingsRepository {
  @override
  Set<ProfilePreference> get supportedPreferences =>
      Set.unmodifiable(ProfilePreference.values);
  @override
  bool get persistsPreferences => false;
  final _settings = <String, ProfileSettings>{};

  @override
  Future<ProfileSettings> getSettings(String userId) async =>
      _settings[userId] ?? const ProfileSettings();

  @override
  Future<void> updateLanguage({
    required String userId,
    required String language,
  }) async {
    final current = _settings[userId] ?? const ProfileSettings();
    _settings[userId] = current.withLanguage(language);
  }

  @override
  Future<ProfileSettings> updatePreference({
    required String userId,
    required ProfilePreference preference,
    required bool enabled,
  }) async {
    final current = _settings[userId] ?? const ProfileSettings();
    final updated = current.withPreference(preference, enabled);
    _settings[userId] = updated;
    return updated;
  }
}
