import 'dart:async';

import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/profile/data/demo_friendship_repository.dart';
import 'package:aprop/features/profile/data/demo_friends_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_repository.dart';
import 'package:aprop/features/profile/data/demo_public_profile_repository.dart';
import 'package:aprop/features/profile/models/received_friend_request.dart';
import 'package:aprop/features/profile/models/public_profile.dart';
import 'package:aprop/features/profile/models/user_summary.dart';
import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/profile/presentation/view_models/friends_list_view_model.dart';
import 'package:aprop/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:aprop/features/profile/presentation/view_models/public_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'friendship_test_support.dart';
import 'remove_friend_test_support.dart';

void main() {
  late ControlledFriendshipRepository friendships;
  late RemovalFriends friends;
  late RemovalProfiles profiles;
  setUp(() {
    friendships = ControlledFriendshipRepository(
      ReceivedFriendRequest(
        senderId: 'peer',
        receiverId: 'viewer',
        sentAt: DateTime.utc(2026, 11, 21),
      ),
    );
    friends = RemovalFriends();
    profiles = RemovalProfiles();
    friendships.onFetch = () async => [];
    friendships.onRemove = () async {
      friends.items = [];
      profiles.friends = false;
    };
  });
  tearDown(() => friendships.dispose());
  FriendsListViewModel list({String? userId}) => FriendsListViewModel(
    repository: friends,
    friendshipRepository: friendships,
    currentUserId: 'viewer',
    userId: userId,
  );
  PublicProfileViewModel profile() => PublicProfileViewModel(
    userId: 'peer',
    currentUserId: 'viewer',
    repository: profiles,
    friendshipRepository: friendships,
  );

  test('Failure preserves both screens; confirmed retry removes the row and clears visible plans', () async {
    final rows = list();
    final peer = profile();
    addTearDown(rows.dispose);
    addTearDown(peer.dispose);
    await Future.wait([rows.load(), peer.load()]);
    friendships.onRemove = () async => throw StateError('offline');
    expect(await rows.removeFriend('peer'), isFalse);
    expect(rows.friends, hasLength(1));
    expect(rows.removalError('peer'), isNotNull);
    expect(peer.friendship, FriendshipAction.friends);
    friendships.onRemove = () async {
      profiles.friends = false;
      friends.items = [];
    };
    expect(await rows.removeFriend('peer'), isTrue);
    await drainRemovalChanges();
    expect(rows.friends, isEmpty);
    expect(peer.friendship, FriendshipAction.add);
    expect(peer.pastPlans, isNull);
    expect(peer.profile!.plansVisible, isFalse);
    expect(peer.profile!.profile.friendCount, 3);
  });

  test(
    'Profile action waits for confirmation and ignores repeated taps',
    () async {
      final peer = profile();
      addTearDown(peer.dispose);
      await peer.load();
      final pending = Completer<void>();
      friendships.onRemove = () async {
        await pending.future;
        profiles.friends = false;
      };
      final removed = peer.removeFriend();
      expect(peer.isRemovingFriend, isTrue);
      expect(await peer.removeFriend(), isFalse);
      expect(peer.friendship, FriendshipAction.friends);
      expect(peer.profile!.plansVisible, isTrue);
      pending.complete();
      expect(await removed, isTrue);
      await drainRemovalChanges();
      expect(friendships.removals, hasLength(1));
      expect(peer.friendship, FriendshipAction.add);
      expect(peer.profile!.isFriend, isFalse);
    },
  );

  test('Other people’s lists cannot remove their friendships', () async {
    final rows = list(userId: 'someone-else');
    addTearDown(rows.dispose);
    await rows.load();
    expect(rows.canRemoveFriends, isFalse);
    expect(await rows.removeFriend('peer'), isFalse);
    expect(friendships.removals, isEmpty);
  });

  test(
    'A new incoming request from a removed friend remains actionable',
    () async {
      final peer = profile();
      addTearDown(peer.dispose);
      await peer.load();
      expect(await peer.removeFriend(), isTrue);
      await drainRemovalChanges();
      expect(peer.friendship, FriendshipAction.add);
      friendships.onFetch = () async => [
        ReceivedFriendRequest(
          senderId: 'peer',
          receiverId: 'viewer',
          sentAt: DateTime.utc(2026, 11, 22),
        ),
      ];
      await peer.load();
      expect(peer.friendship, FriendshipAction.incoming);
    },
  );

  test(
    'Removing someone else does not erase a pending outgoing request',
    () async {
      final peer = profile();
      addTearDown(peer.dispose);
      await peer.load();
      await peer.removeFriend();
      await drainRemovalChanges();
      await peer.sendFriendRequest();
      expect(peer.friendship, FriendshipAction.requestSent);
      final reads = profiles.reads;
      await friendships.removeFriend(
        userId: 'viewer',
        friendId: 'another-peer',
      );
      await drainRemovalChanges();
      expect(peer.friendship, FriendshipAction.requestSent);
      expect(profiles.reads, reads);
    },
  );

  test('A fresh server profile and list recognize an externally restored friendship', () async {
    final peer = profile();
    final rows = list();
    addTearDown(peer.dispose);
    addTearDown(rows.dispose);
    await Future.wait([peer.load(), rows.load()]);
    await peer.removeFriend();
    await drainRemovalChanges();
    profiles.friends = true;
    friends.items = [removalPeer];
    await Future.wait([peer.load(), rows.load()]);
    expect(peer.friendship, FriendshipAction.friends);
    expect(peer.profile!.plansVisible, isTrue);
    expect(rows.friends!.single.id, 'peer');
    expect(friendships.confirmedFriendship('viewer', 'peer'), isNot(false));
  });

  test('A fresh negative profile overrides old positive reads and accepted history', () async {
    profiles.friends = false;
    friendships.onFetch = () async => [friendships.request];
    final peer = profile();
    addTearDown(peer.dispose);
    await peer.load();
    friendships.onRespond = (_) async {
      profiles.friends = true;
      return FriendRequestResolution(
        request: friendships.request,
        status: FriendRequestStatus.accepted,
      );
    };
    await peer.acceptFriendRequest();
    await drainRemovalChanges();
    expect(peer.friendship, FriendshipAction.friends);
    profiles.friends = false;
    await peer.load();
    expect(peer.friendship, FriendshipAction.add);
    expect(peer.canRemoveFriend, isFalse);
    expect(peer.profile!.plansVisible, isFalse);
    expect(peer.pastPlans, isNull);
  });

  test('An old list refresh cannot reinsert a confirmed removal', () async {
    final rows = list();
    addTearDown(rows.dispose);
    await rows.load();
    final pending = Completer<List<UserSummary>>();
    friends.onGet = () => pending.future;
    final loading = rows.load();
    await friendships.removeFriend(userId: 'viewer', friendId: 'peer');
    friends.onGet = null;
    friends.items = [];
    pending.complete([removalPeer]);
    await loading;
    await drainRemovalChanges();
    expect(rows.friends, isEmpty);
    expect(rows.errorMessage, isNull);
  });

  test(
    'An old profile refresh cannot restore friendship or stale counters',
    () async {
      final peer = profile();
      addTearDown(peer.dispose);
      await peer.load();
      final pending = Completer<PublicProfile>();
      final stale = profiles.snapshot();
      profiles.onGet = () => pending.future;
      final loading = peer.load();
      await friendships.removeFriend(userId: 'viewer', friendId: 'peer');
      profiles.onGet = null;
      profiles.friends = false;
      pending.complete(stale);
      await loading;
      await drainRemovalChanges();
      expect(peer.friendship, FriendshipAction.add);
      expect(peer.profile!.profile.friendCount, 3);
      expect(peer.profile!.plansVisible, isFalse);
    },
  );

  test('Plans completing after removal stay private', () async {
    final peer = profile();
    addTearDown(peer.dispose);
    final plans = Completer<List<Activity>>();
    profiles.onPlans = () => plans.future;
    final loading = peer.load();
    await drainRemovalChanges();
    expect(peer.isLoadingPlans, isTrue);
    await friendships.removeFriend(userId: 'viewer', friendId: 'peer');
    plans.complete(await DemoActivityRepository().getActivities());
    await loading;
    await drainRemovalChanges();
    expect(peer.pastPlans, isNull);
    expect(peer.profile!.plansVisible, isFalse);
  });

  test('Demo removal updates both counters, profile friendship and own list from one source', () async {
    const profileUser = AppUser(
      id: 'demo-laiasoler',
      email: 'laia@example.test',
      firstName: 'Laia',
      lastName: 'Soler',
      username: 'laiasoler',
      emailVerified: true,
    );
    final shared = DemoFriendshipRepository();
    addTearDown(shared.dispose);
    final activities = DemoActivityRepository();
    final own = ProfileViewModel(
      user: profileUser,
      repository: DemoProfileRepository(
        activityRepository: activities,
        friendshipRepository: shared,
      ),
      friendshipRepository: shared,
    );
    final peer = PublicProfileViewModel(
      userId: 'demo-person-julia',
      currentUserId: profileUser.id,
      repository: DemoPublicProfileRepository(
        activityRepository: activities,
        friendshipRepository: shared,
        currentUserId: () => profileUser.id,
      ),
      friendshipRepository: shared,
    );
    final rows = FriendsListViewModel(
      repository: DemoFriendsRepository(
        friendshipRepository: shared,
        currentUserId: () => profileUser.id,
      ),
      currentUserId: profileUser.id,
      friendshipRepository: shared,
    );
    addTearDown(own.dispose);
    addTearDown(peer.dispose);
    addTearDown(rows.dispose);
    await Future.wait([own.load(), peer.load(), rows.load()]);
    final before = own.profile!.friendCount;
    expect(await peer.removeFriend(), isTrue);
    await drainRemovalChanges();
    expect(own.profile!.friendCount, before > 0 ? before - 1 : 0);
    expect(peer.profile!.profile.friendCount, 7);
    expect(peer.friendship, FriendshipAction.add);
    expect(rows.friends!.any((f) => f.id == 'demo-person-julia'), isFalse);
  });

  test('A disposed list ignores completion of its removal', () async {
    final rows = list();
    await rows.load();
    final pending = Completer<void>();
    friendships.onRemove = () => pending.future;
    final removal = rows.removeFriend('peer');
    rows.dispose();
    pending.complete();
    expect(await removal, isFalse);
  });
}
