import '../../auth/models/app_user.dart';
import '../models/user_profile.dart';
import '../models/profile_capabilities.dart';
import '../models/profile_avatar.dart';
import '../../activities/models/activity.dart';

abstract interface class ProfileRepository {
  ProfileCapabilities get capabilities;

  /// Returns the signed-in account's metadata; created activities load separately.
  /// Throws on a data-access failure; no other account may be substituted.
  Future<UserProfile> getProfile(AppUser user);

  /// A separate failure must not turn a failed collection into an empty one.
  Future<List<Activity>> getCreatedActivities(AppUser user);

  /// Confirms supported edits or throws without claiming success.
  /// Optional identity fields are available only with editIdentity capability.
  Future<UserProfile> updateDetails({
    required AppUser user,
    required String biography,
    required String municipality,
    String? name,
    String? username,
  });

  Future<UserProfile> uploadAvatar({
    required AppUser user,
    required ProfileAvatar avatar,
  });
}
