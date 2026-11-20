import 'package:aprop/features/profile/data/cached_friendship_repository.dart';
import 'package:aprop/features/profile/models/received_friend_request.dart';

class ControlledFriendshipRepository extends CachedFriendshipRepository {
  ControlledFriendshipRepository(this.request);
  final ReceivedFriendRequest request;
  Future<List<ReceivedFriendRequest>> Function()? onFetch;
  Future<FriendRequestResolution> Function(bool accept)? onRespond;
  int reads = 0;
  int writes = 0;
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
