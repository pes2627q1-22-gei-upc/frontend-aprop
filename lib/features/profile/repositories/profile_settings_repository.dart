import '../models/profile_settings.dart';

abstract interface class ProfileSettingsRepository {
  Set<ProfilePreference> get supportedPreferences;
  bool get persistsPreferences;

  /// Returns this account's preferences, or its defaults. Throws on failure.
  Future<ProfileSettings> getSettings(String userId);

  /// Stores the UI language (`ca`, `es` or `en`) on the account. Throws on failure.
  Future<void> updateLanguage({
    required String userId,
    required String language,
  });

  /// Applies one preference and returns the confirmed snapshot. Throws on failure.
  Future<ProfileSettings> updatePreference({
    required String userId,
    required ProfilePreference preference,
    required bool enabled,
  });
}
