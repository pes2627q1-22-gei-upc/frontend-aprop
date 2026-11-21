import '../models/notification_preferences.dart';
import '../models/profile_settings.dart';

/// API IDs are generated; only these protocol names define configurable types.
Map<ProfilePreference, int> notificationPreferenceTypes(Object? decoded) {
  if (decoded is! List<Object?>) {
    throw const FormatException('Expected the notification type catalogue');
  }
  final ids = <int>{};
  final types = <ProfilePreference, int>{};
  for (final item in decoded) {
    if (item is! Map<String, Object?> ||
        item['id'] is! int ||
        (item['id'] as int) <= 0 ||
        item['name'] is! String ||
        (item['name'] as String).trim().isEmpty) {
      throw const FormatException('Invalid notification type');
    }
    final id = item['id'] as int;
    if (!ids.add(id)) {
      throw const FormatException('Duplicate notification type ID');
    }
    final name = (item['name'] as String)
        .trim()
        .toLowerCase()
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o');
    final preference = switch (name) {
      'recordatori' => ProfilePreference.reminders,
      'social' => ProfilePreference.social,
      'recomanacio' => ProfilePreference.recommendations,
      'cancelacio' => ProfilePreference.cancellations,
      _ => null,
    };
    if (preference == null) continue;
    if (types.containsKey(preference)) {
      throw const FormatException('Ambiguous notification type');
    }
    types[preference] = id;
  }
  if (types.isEmpty) {
    throw const FormatException('No configurable notification types');
  }
  return Map.unmodifiable(types);
}

class NotificationPreferencesPayload {
  NotificationPreferencesPayload.fromJson(Object? decoded) {
    if (decoded is! Map<String, Object?> ||
        decoded['id'] is! int ||
        (decoded['id'] as int) <= 0 ||
        decoded['allowed-notif-types'] is! List<Object?>) {
      throw const FormatException('Expected account notification settings');
    }
    settingsId = decoded['id'] as int;
    final allowed = <int>{};
    for (final id in decoded['allowed-notif-types'] as List<Object?>) {
      if (id is! int || id <= 0 || !allowed.add(id)) {
        throw const FormatException('Invalid allowed notification types');
      }
    }
    allowedIds = Set.unmodifiable(allowed);
  }

  late final int settingsId;
  late final Set<int> allowedIds;

  NotificationPreferences preferences(Map<ProfilePreference, int> types) =>
      NotificationPreferences({
        for (final entry in types.entries)
          entry.key: allowedIds.contains(entry.value),
      });
}
