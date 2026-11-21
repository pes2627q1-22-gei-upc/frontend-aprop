import '../models/received_friend_request.dart';
import 'cached_friendship_repository.dart';

/// Session-only demo data, isolated by signed-in account.
class DemoFriendshipRepository extends CachedFriendshipRepository {
  @override
  String peerId(String value) =>
      value == 'demo-person-laia' ? 'demo-laiasoler' : value;

  @override
  Future<void> sendRemoval(String userId, String friendId) async {
    if (userId.isEmpty || friendId.isEmpty || userId == friendId) {
      throw ArgumentError('Expected another demo person');
    }
  }

  static ReceivedFriendRequest marcRequest(String userId) =>
      ReceivedFriendRequest(
        senderId: 'demo-person-marc',
        receiverId: userId,
        sentAt: DateTime.utc(2026, 9, 26, 14, 30),
      );

  bool hasAccepted(String userId, String peerId) =>
      confirmedFriendship(userId, peerId) == true;
  int acceptedCount(String userId) => resolutions(userId)
      .where(
        (r) =>
            r.status == FriendRequestStatus.accepted &&
            confirmedFriendship(userId, r.request.senderId) != false,
      )
      .map((r) => peerId(r.request.senderId))
      .toSet()
      .length;

  @override
  Future<List<ReceivedFriendRequest>> fetchReceived(String userId) async {
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');
    return userId == 'demo-person-marc' ? const [] : [marcRequest(userId)];
  }

  @override
  Future<FriendRequestResolution> sendResponse(
    String userId,
    ReceivedFriendRequest request,
    bool accept,
  ) async {
    if (request.id != marcRequest(userId).id || request.senderId == userId) {
      throw StateError('Received request not found');
    }
    return FriendRequestResolution(
      request: request,
      status: accept
          ? FriendRequestStatus.accepted
          : FriendRequestStatus.rejected,
    );
  }
}
