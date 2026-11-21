import '../models/blocked_user.dart';
import '../models/user_summary.dart';

/// Personal blocking. Failures propagate; an unknown list is not an empty one.
abstract interface class UserBlockingRepository {
  Future<List<BlockedUser>> getBlockedUsers(String userId);
  List<BlockedUser>? cachedBlockedUsers(String userId);
  bool? isBlocked(String userId, String targetId);
  Future<BlockedUser> blockUser({
    required String userId,
    required UserSummary target,
  });
  Future<void> unblockUser({required String userId, required String targetId});
  Stream<void> watchBlocks(String userId);
}
