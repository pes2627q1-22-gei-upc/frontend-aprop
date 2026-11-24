import '../models/profile_settings.dart';
import '../models/notification_preferences.dart';

abstract interface class ProfileSettingsRepository {
  Set<ProfilePreference> get supportedPreferences;
  bool get persistsPreferences;

  /// Returns this account's preferences, or its defaults. Throws on failure.
  Future<ProfileSettings> getSettings(String userId);

  /// Reads delivery preferences and available types. Throws on failure;
  /// an empty or unavailable catalogue is not an all-disabled snapshot.
  Future<NotificationPreferences> getNotificationPreferences(String userId);

  /// Updates one delivery preference, preserving all other allowed types,
  /// and returns the confirmed notification snapshot. Throws on failure.
  Future<NotificationPreferences> updateNotificationPreference({
    required String userId,
    required ProfilePreference preference,
    required bool enabled,
  });

  /// Stores the UI language (`ca`, `es` or `en`) on the account. Throws on failure.
  Future<void> updateLanguage({
    required String userId,
    required String language,
  });

  /// Applies plan-sharing privacy. Delivery preferences use
  /// [updateNotificationPreference]. Throws without a confirmed response.
  Future<ProfileSettings> updatePreference({
    required String userId,
    required ProfilePreference preference,
    required bool enabled,
  });
}
