import 'package:aprop/features/profile/data/cached_friendship_repository.dart';
import 'package:aprop/features/profile/models/received_friend_request.dart';
import 'package:aprop/features/profile/models/blocked_user.dart';
import 'package:aprop/features/profile/models/user_summary.dart';

class ControlledFriendshipRepository extends CachedFriendshipRepository {
  ControlledFriendshipRepository(this.request);
  final ReceivedFriendRequest request;
  Future<List<ReceivedFriendRequest>> Function()? onFetch;
  Future<FriendRequestResolution> Function(bool accept)? onRespond;
  int reads = 0;
  int writes = 0;
  final removals = <(String, String)>[];
  Future<void> Function()? onRemove;
  Future<List<BlockedUser>> Function()? onFetchBlocked;
  Future<BlockedUser> Function(UserSummary)? onBlock;
  Future<void> Function(String)? onUnblock;
  final blocks = <UserSummary>[];
  final unblocks = <String>[];
  final blockedUsers = <String, BlockedUser>{};

  @override
  Future<List<BlockedUser>> fetchBlocked(String userId) async =>
      onFetchBlocked == null ? List.of(blockedUsers.values) : onFetchBlocked!();

  @override
  Future<BlockedUser> sendBlock(String userId, UserSummary target) async {
    blocks.add(target);
    final row =
        await onBlock?.call(target) ??
        BlockedUser(user: target, blockedAt: DateTime.utc(2026, 11, 21));
    blockedUsers[target.id] = row;
    return row;
  }

  @override
  Future<void> sendUnblock(String userId, String targetId) async {
    unblocks.add(targetId);
    await onUnblock?.call(targetId);
    blockedUsers.remove(targetId);
  }

  @override
  Future<void> sendRemoval(String userId, String friendId) async {
    removals.add((userId, friendId));
    await onRemove?.call();
  }

  @override
  Future<List<ReceivedFriendRequest>> fetchReceived(String userId) async {
    reads++;
    return onFetch == null ? [request] : await onFetch!();
  }

  @override
  Future<FriendRequestResolution> sendResponse(
    String userId,
    ReceivedFriendRequest request,
    bool accept,
  ) async {
    writes++;
    return onRespond == null
        ? FriendRequestResolution(
            request: request,
            status: accept
                ? FriendRequestStatus.accepted
                : FriendRequestStatus.rejected,
          )
        : await onRespond!(accept);
  }
}
