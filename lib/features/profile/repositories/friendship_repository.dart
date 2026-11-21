import '../models/received_friend_request.dart';

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
}
