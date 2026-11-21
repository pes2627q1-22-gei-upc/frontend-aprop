import 'profile_settings.dart';

/// Confirmed delivery preferences, independent of received notifications.
class NotificationPreferences {
  NotificationPreferences(Map<ProfilePreference, bool> values)
    : values = Map.unmodifiable(values) {
    if (values.keys.any((preference) => !types.contains(preference))) {
      throw ArgumentError('Expected notification preferences');
    }
  }

  static const types = {
    ProfilePreference.reminders,
    ProfilePreference.social,
    ProfilePreference.recommendations,
    ProfilePreference.cancellations,
  };

  final Map<ProfilePreference, bool> values;

  bool supports(ProfilePreference preference) => values.containsKey(preference);

  bool valueOf(ProfilePreference preference) {
    final value = values[preference];
    if (value == null) throw UnsupportedError('Unavailable notification type');
    return value;
  }

  NotificationPreferences withPreference(
    ProfilePreference preference,
    bool enabled,
  ) {
    if (!supports(preference)) {
      throw UnsupportedError('Unavailable notification type');
    }
    return NotificationPreferences({...values, preference: enabled});
  }
}
