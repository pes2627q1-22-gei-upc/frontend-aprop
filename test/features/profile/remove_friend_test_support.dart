import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/profile/models/public_profile.dart';
import 'package:aprop/features/profile/models/user_profile.dart';
import 'package:aprop/features/profile/models/user_summary.dart';
import 'package:aprop/features/profile/repositories/friends_repository.dart';
import 'package:aprop/features/profile/repositories/public_profile_repository.dart';

const removalPeer = UserSummary(
  id: 'peer',
  username: 'marcvidal',
  displayName: 'Marc Vidal',
);

Future<void> drainRemovalChanges() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class RemovalFriends implements FriendsRepository {
  List<UserSummary> items = [removalPeer];
  Future<List<UserSummary>> Function()? onGet;
  int reads = 0;
  @override
  Future<List<UserSummary>> getFriends({String? userId}) async {
    reads++;
    return onGet == null ? List.of(items) : onGet!();
  }
}

class RemovalProfiles implements PublicProfileRepository {
  bool friends = true;
  int reads = 0;
  Future<PublicProfile> Function()? onGet;
  Future<List<Activity>> Function()? onPlans;
  PublicProfile snapshot() => PublicProfile(
    profile: UserProfile(
      userId: removalPeer.id,
      username: removalPeer.username,
      displayName: removalPeer.displayName,
      friendCount: friends ? 4 : 3,
      progress: const ProfileProgress(level: null, experience: 0),
    ),
    isFriend: friends,
    plansVisible: friends,
  );
  @override
  Future<PublicProfile> getPublicProfile(String userId) async {
    reads++;
    return onGet == null ? snapshot() : onGet!();
  }

  @override
  Future<List<Activity>> getCreatedActivities(String userId) async => [];
  @override
  Future<List<Activity>> getPastPlans(String userId) async =>
      onPlans == null ? [] : onPlans!();
  @override
  Future<FriendRequestResult> sendFriendRequest(String userId) async =>
      FriendRequestResult.sent;
}
