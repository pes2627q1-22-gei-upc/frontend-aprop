import '../../auth/models/app_user.dart';
import '../models/user_profile.dart';

UserProfile profileFromJson(Map<String, Object?> json, AppUser account) =>
    userProfileFromJson(json, userId: account.id);

/// Same mapping for any person; [userId] is the ID the profile is kept under.
UserProfile userProfileFromJson(
  Map<String, Object?> json, {
  required String userId,
}) {
  String text(String field) {
    if (json[field] case final String value) return value.trim();
    throw FormatException('Expected profile $field');
  }

  int count(String field) {
    if (json[field] case final int value when value >= 0) return value;
    throw FormatException('Expected non-negative $field');
  }

  final username = text('username');
  if (username.isEmpty) throw const FormatException('Expected a username');
  final rawName = text('name');
  final picture = text('profile-picture');
  final uri = Uri.tryParse(picture);
  final avatarUrl =
      uri != null &&
          {'http', 'https'}.contains(uri.scheme) &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? uri.toString()
      : null;
  final rawLevel = json['level'];
  if (rawLevel != null && (rawLevel is! int || rawLevel < 1)) {
    throw const FormatException('Expected a nullable level ID');
  }
  final rawRating = json['reliability'] ?? json['rating'];
  if (rawRating != null &&
      (rawRating is! num ||
          !rawRating.isFinite ||
          rawRating < 0 ||
          rawRating > 5)) {
    throw const FormatException('Invalid organizer rating');
  }
  return UserProfile(
    userId: userId,
    displayName: rawName.isEmpty ? username : rawName,
    username: username,
    biography: text('biography'),
    avatarUrl: avatarUrl,
    planCount: count('plans-count'),
    friendCount: count('friends-count'),
    organizerRating: rawRating is num && rawRating > 0
        ? rawRating.toDouble()
        : null,
    // TODO(DP-040): The API returns a level FK, not labels or XP thresholds.
    // Keep reported XP/ID without inventing a five-level progression.
    progress: ProfileProgress(
      level: null,
      experience: count('experience'),
      serverLevel: rawLevel as int?,
    ),
  );
}
