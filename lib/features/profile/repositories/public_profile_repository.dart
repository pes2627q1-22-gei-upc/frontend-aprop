import '../../activities/models/activity.dart';
import '../models/public_profile.dart';

/// Reads other people's profiles. Each call throws on failure; an error must
/// never turn into an empty list.
abstract interface class PublicProfileRepository {
  /// Throws [PublicProfileNotFound] if the person does not exist.
  Future<PublicProfile> getPublicProfile(String userId);

  Future<List<Activity>> getCreatedActivities(String userId);

  /// Plans the person already went to. Call it only when
  /// [PublicProfile.plansVisible] is true.
  Future<List<Activity>> getPastPlans(String userId);

  /// Sends a friend request to [userId] (#160). A refusal the server explains
  /// comes back as a result; any other failure throws.
  Future<FriendRequestResult> sendFriendRequest(String userId);
}

/// What happened when sending a friend request.
enum FriendRequestResult {
  sent,

  /// There already is a pending request between both, in either direction.
  alreadyPending,
  alreadyFriends,

  /// One of the two has blocked the other.
  blocked,
}

class PublicProfileNotFound implements Exception {
  const PublicProfileNotFound();
}
