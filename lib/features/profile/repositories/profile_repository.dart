import '../../auth/models/app_user.dart';
import '../models/user_profile.dart';

abstract interface class ProfileRepository {
  /// Returns the signed-in account's profile, including empty collections.
  /// Throws on a data-access failure; no other account may be substituted.
  Future<UserProfile> getProfile(AppUser user);

  /// Confirms edited optional details or throws without claiming success.
  /// Identity/username changes require the separate authenticated contract.
  Future<UserProfile> updateDetails({
    required AppUser user,
    required String biography,
    required String municipality,
  });
}
