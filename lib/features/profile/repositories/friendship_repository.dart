import '../models/received_friend_request.dart';
import '../models/friendship_removal.dart';

/// Shared, account-scoped source of received requests and confirmed responses.
/// Errors propagate; callers must never replace a failure with a local success.
abstract interface class FriendshipRepository {
  Future<List<ReceivedFriendRequest>> getReceivedRequests(String userId);
  Future<FriendRequestResolution> respond({
    required String userId,
    required String requestId,
    required bool accept,
  });
  Stream<FriendRequestResolution> watchChanges(String userId);

  /// Session-only confirmations, also used to reconcile a stale refresh.
  List<FriendRequestResolution> resolutions(String userId);

  /// Removes a friendship only after confirmation by the data source. Throws
  /// on failure; concurrent removals of the same friend share one operation.
  Future<void> removeFriend({required String userId, required String friendId});
  Stream<FriendshipRemoval> watchRemovals(String userId);

  /// Session confirmations for reconciling stale profiles and lists. Null
  /// means unknown, not "not friends". Historical requests remain resolved.
  bool? confirmedFriendship(String userId, String friendId);
  Set<String> removedFriends(String userId);

  /// Reconciles positive relationships from a fresh authoritative read. The
  /// caller must discard reads started before its last observed change.
  void reconcileFriends(String userId, Iterable<String> friendIds);
}
