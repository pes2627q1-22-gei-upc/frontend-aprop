import '../models/user_summary.dart';
import '../repositories/friends_repository.dart';
import 'demo_public_profile_repository.dart';
import '../repositories/friendship_repository.dart';

/// The example people of [DemoPublicProfileRepository] as friends.
class DemoFriendsRepository implements FriendsRepository {
  DemoFriendsRepository({this.friendshipRepository, this.currentUserId});
  final FriendshipRepository? friendshipRepository;
  final String? Function()? currentUserId;

  @override
  Future<List<UserSummary>> getFriends({String? userId}) async {
    final viewer = currentUserId?.call();
    final friends = DemoPublicProfileRepository.friendsOf(userId);
    if (viewer == null || friendshipRepository == null) return friends;
    if (userId != null) {
      if (friendshipRepository!.confirmedFriendship(viewer, userId) == false) {
        return List.unmodifiable(friends.where((f) => f.id != viewer));
      }
      return friends;
    }
    return List.unmodifiable([
      for (final person in DemoPublicProfileRepository.searchablePeople)
        if (friendshipRepository!.confirmedFriendship(viewer, person.id) ==
                true ||
            (friends.any((f) => f.id == person.id) &&
                friendshipRepository!.confirmedFriendship(viewer, person.id) !=
                    false))
          person,
    ]);
  }
}
