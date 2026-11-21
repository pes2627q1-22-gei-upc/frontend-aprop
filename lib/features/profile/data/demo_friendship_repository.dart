import '../models/received_friend_request.dart';
import '../models/blocked_user.dart';
import '../models/user_summary.dart';
import 'cached_friendship_repository.dart';

/// Session-only demo data, isolated by signed-in account.
class DemoFriendshipRepository extends CachedFriendshipRepository {
  DemoFriendshipRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final _demoBlocks = <String, Map<String, BlockedUser>>{};
  final _cancelledRequests = <(String, String)>{};

  @override
  Future<List<BlockedUser>> fetchBlocked(String userId) async =>
      List.unmodifiable(_demoBlocks[userId]?.values ?? const <BlockedUser>[]);

  @override
  Future<BlockedUser> sendBlock(String userId, UserSummary target) async {
    final id = peerId(target.id);
    _cancelledRequests.add((userId, id));
    final row = BlockedUser(
      user: UserSummary(
        id: id,
        username: target.username,
        displayName: target.displayName,
        avatarAsset: target.avatarAsset,
        avatarUrl: target.avatarUrl,
      ),
      blockedAt: _now().toUtc(),
    );
    return (_demoBlocks[userId] ??= {})[id] ??= row;
  }

  @override
  Future<void> sendUnblock(String userId, String targetId) async {
    _demoBlocks[userId]?.remove(targetId);
  }

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
    return userId == 'demo-person-marc' ||
            _cancelledRequests.contains((userId, 'demo-person-marc'))
        ? const []
        : [marcRequest(userId)];
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
