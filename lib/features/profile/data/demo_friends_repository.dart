import '../models/user_summary.dart';
import '../repositories/friends_repository.dart';
import 'demo_public_profile_repository.dart';

/// The example people of [DemoPublicProfileRepository] as friends.
class DemoFriendsRepository implements FriendsRepository {
  @override
  Future<List<UserSummary>> getFriends({String? userId}) async =>
      DemoPublicProfileRepository.friendsOf(userId);
}
