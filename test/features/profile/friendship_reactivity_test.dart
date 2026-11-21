import 'dart:async';

import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/notifications/data/demo_notification_repository.dart';
import 'package:aprop/features/notifications/presentation/view_models/notifications_view_model.dart';
import 'package:aprop/features/profile/data/demo_friendship_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_repository.dart';
import 'package:aprop/features/profile/data/demo_public_profile_repository.dart';
import 'package:aprop/features/profile/models/public_profile.dart';
import 'package:aprop/features/profile/models/received_friend_request.dart';
import 'package:aprop/features/profile/models/user_profile.dart';
import 'package:aprop/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:aprop/features/profile/presentation/view_models/public_profile_view_model.dart';
import 'package:aprop/features/profile/repositories/public_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_profile_repositories.dart';
import 'friendship_test_support.dart';
import 'profile_test_data.dart';

Future<void> drain() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Profiles implements PublicProfileRepository {
  bool friends = false;
  int reads = 0;
  Future<PublicProfile> Function()? onGet;
  Future<FriendRequestResult> Function()? onSend;
  PublicProfile snapshot() => PublicProfile(
    profile: UserProfile(
      userId: 'demo-person-marc',
      displayName: 'Marc Vidal',
      username: 'marcvidal',
      friendCount: friends ? 4 : 3,
      progress: const ProfileProgress(level: null, experience: 0),
    ),
    isFriend: friends,
    plansVisible: false,
  );
  @override
  Future<PublicProfile> getPublicProfile(String id) async {
    reads++;
    return onGet == null ? snapshot() : await onGet!();
  }

  @override
  Future<List<Activity>> getCreatedActivities(String id) async => [];
  @override
  Future<List<Activity>> getPastPlans(String id) async =>
      throw StateError('Private plans must not be fetched');
  @override
  Future<FriendRequestResult> sendFriendRequest(String id) async =>
      onSend == null
      ? throw StateError('Incoming requests must be accepted, not sent')
      : await onSend!();
}

void main() {
  test('Accepting in either view updates inbox, open profile badge and both real counters', () async {
    for (final fromInbox in [true, false]) {
      final friendships = DemoFriendshipRepository();
      final activities = DemoActivityRepository();
      final own = ProfileViewModel(
        user: profileUser,
        repository: DemoProfileRepository(
          activityRepository: activities,
          friendshipRepository: friendships,
        ),
        friendshipRepository: friendships,
      );
      final peer = PublicProfileViewModel(
        userId: 'demo-person-marc',
        currentUserId: profileUser.id,
        repository: DemoPublicProfileRepository(
          activityRepository: activities,
          friendshipRepository: friendships,
          currentUserId: () => profileUser.id,
        ),
        friendshipRepository: friendships,
      );
      final inbox = NotificationsViewModel(
        userId: profileUser.id,
        repository: DemoNotificationRepository(
          activityRepository: activities,
          friendshipRepository: friendships,
        ),
        friendshipRepository: friendships,
      );
      await Future.wait([own.load(), peer.load(), inbox.load()]);
      expect(peer.friendship, FriendshipAction.incoming);
      expect(own.profile!.friendCount, 0);
      expect(peer.profile!.profile.friendCount, 3);
      if (fromInbox) {
        await inbox.respond('demo-request-notice', accept: true);
      } else {
        await peer.acceptFriendRequest();
      }
      await drain();
      expect(peer.friendship, FriendshipAction.friends);
      expect(peer.profile!.profile.friendCount, 4);
      expect(own.profile!.friendCount, 1);
      expect(peer.profile!.plansVisible, isFalse);
      expect(peer.pastPlans, isNull);
      expect(
        inbox.notifications
            .firstWhere((n) => n.id == 'demo-request-notice')
            .requestStatus,
        FriendRequestStatus.accepted,
      );
      await inbox.load();
      await peer.load();
      await own.load();
      expect(own.profile!.friendCount, 1);
      expect(peer.profile!.profile.friendCount, 4);
      expect(
        inbox.notifications
            .firstWhere((n) => n.id == 'demo-request-notice')
            .requestStatus,
        FriendRequestStatus.accepted,
      );
      expect(
        (await friendships.getReceivedRequests('other-account')),
        hasLength(1),
      );
      expect(friendships.acceptedCount('other-account'), 0);
      own.dispose();
      peer.dispose();
      inbox.dispose();
      await friendships.dispose();
    }
  });

  test('Profile accept waits for confirmation, prevents duplicates, and permits retry', () async {
    final request = DemoFriendshipRepository.marcRequest(profileUser.id);
    final friendships = ControlledFriendshipRepository(request);
    final profiles = _Profiles();
    final model = PublicProfileViewModel(
      userId: request.senderId,
      currentUserId: profileUser.id,
      repository: profiles,
      friendshipRepository: friendships,
    );
    await model.load();
    final pending = Completer<FriendRequestResolution>();
    friendships.onRespond = (_) => pending.future;
    final accepting = model.acceptFriendRequest();
    await model.acceptFriendRequest();
    expect(model.friendship, FriendshipAction.accepting);
    expect(model.profile!.profile.friendCount, 3);
    expect(friendships.writes, 1);
    pending.completeError(StateError('offline'));
    await accepting;
    expect(model.friendship, FriendshipAction.incoming);
    expect(model.friendRequestError, isNotNull);
    expect(friendships.resolutions(profileUser.id), isEmpty);
    friendships.onRespond = (_) async {
      profiles.friends = true;
      return FriendRequestResolution(
        request: request,
        status: FriendRequestStatus.accepted,
      );
    };
    await model.acceptFriendRequest();
    await drain();
    expect(model.friendship, FriendshipAction.friends);
    expect(model.profile!.profile.friendCount, 4);
    expect(model.friendRequestError, isNull);
    model.dispose();
    await friendships.dispose();
  });

  test(
    'Pending-request lookup failure offers retry, not a misleading Add button',
    () async {
      final friendships = ControlledFriendshipRepository(
        DemoFriendshipRepository.marcRequest(profileUser.id),
      )..onFetch = () async => throw StateError('offline');
      final model = PublicProfileViewModel(
        userId: 'demo-person-marc',
        currentUserId: profileUser.id,
        repository: _Profiles(),
        friendshipRepository: friendships,
      );
      await model.load();
      expect(model.profile, isNotNull);
      expect(model.friendship, FriendshipAction.retry);
      friendships.onFetch = null;
      await model.performFriendAction();
      expect(model.friendship, FriendshipAction.incoming);
      model.dispose();
      await friendships.dispose();
    },
  );

  test(
    'Confirmation during a stale public-profile reload schedules a fresh read',
    () async {
      final request = DemoFriendshipRepository.marcRequest(profileUser.id);
      final friendships = ControlledFriendshipRepository(request);
      final profiles = _Profiles();
      final model = PublicProfileViewModel(
        userId: request.senderId,
        currentUserId: profileUser.id,
        repository: profiles,
        friendshipRepository: friendships,
      );
      await model.load();
      final pending = Completer<PublicProfile>();
      final old = profiles.snapshot();
      profiles.onGet = () => pending.future;
      final loading = model.load();
      profiles.friends = true;
      profiles.onGet = null;
      await friendships.respond(
        userId: profileUser.id,
        requestId: request.id,
        accept: true,
      );
      pending.complete(old);
      await loading;
      await drain();
      expect(model.friendship, FriendshipAction.friends);
      expect(model.profile!.profile.friendCount, 4);
      model.dispose();
      await friendships.dispose();
    },
  );

  test('Own counter refresh is queued while saving and is never incremented speculatively', () async {
    final request = DemoFriendshipRepository.marcRequest(profileUser.id);
    final friendships = ControlledFriendshipRepository(request);
    final repository = FakeProfileRepository();
    final model = ProfileViewModel(
      user: profileUser,
      repository: repository,
      friendshipRepository: friendships,
    );
    await model.load();
    final pending = Completer<UserProfile>();
    repository.onUpdate = (_, _, _) => pending.future;
    final saving = model.saveDetails(biography: 'Cinema', municipality: 'Vic');
    await friendships.getReceivedRequests(profileUser.id);
    await friendships.respond(
      userId: profileUser.id,
      requestId: request.id,
      accept: true,
    );
    expect(repository.users, hasLength(1));
    expect(model.profile!.friendCount, 14);
    repository.profile = UserProfile(
      userId: profileUser.id,
      displayName: 'Adam',
      friendCount: 15,
      progress: const ProfileProgress(level: null, experience: 0),
    );
    pending.complete(
      sampleProfile().withDetails(biography: 'Cinema', municipality: 'Vic'),
    );
    await saving;
    await drain();
    expect(repository.users, hasLength(2));
    expect(model.profile!.friendCount, 15);
    model.dispose();
    await friendships.dispose();
  });

  for (final fails in [false, true]) {
    test(
      'An old outgoing request ${fails ? 'error' : 'success'} cannot overwrite a new confirmed friendship',
      () async {
        final request = DemoFriendshipRepository.marcRequest(profileUser.id);
        final friendships = ControlledFriendshipRepository(request)
          ..onFetch = () async => [];
        final pending = Completer<FriendRequestResult>();
        final profiles = _Profiles()..onSend = () => pending.future;
        final model = PublicProfileViewModel(
          userId: request.senderId,
          currentUserId: profileUser.id,
          repository: profiles,
          friendshipRepository: friendships,
        );
        await model.load();
        expect(model.friendship, FriendshipAction.add);
        final sending = model.sendFriendRequest();
        friendships.onFetch = null;
        await friendships.getReceivedRequests(profileUser.id);
        profiles.friends = true;
        await friendships.respond(
          userId: profileUser.id,
          requestId: request.id,
          accept: true,
        );
        await drain();
        if (fails) {
          pending.completeError(StateError('late failure'));
        } else {
          pending.complete(FriendRequestResult.alreadyPending);
        }
        await sending;
        await drain();
        expect(model.friendship, FriendshipAction.friends);
        expect(model.friendRequestError, isNull);
        expect(model.profile!.profile.friendCount, 4);
        model.dispose();
        await friendships.dispose();
      },
    );
  }

  test(
    'A successful profile acceptance clears a previous inbox response error',
    () async {
      final request = DemoFriendshipRepository.marcRequest(profileUser.id);
      final friendships = ControlledFriendshipRepository(request)
        ..onRespond = (_) async => throw StateError('offline');
      final activities = DemoActivityRepository();
      final inbox = NotificationsViewModel(
        userId: profileUser.id,
        repository: DemoNotificationRepository(
          activityRepository: activities,
          friendshipRepository: friendships,
        ),
        friendshipRepository: friendships,
      );
      final profiles = _Profiles();
      final model = PublicProfileViewModel(
        userId: request.senderId,
        currentUserId: profileUser.id,
        repository: profiles,
        friendshipRepository: friendships,
      );
      await inbox.load();
      await model.load();
      await inbox.respond('demo-request-notice', accept: true);
      expect(inbox.errorFor('demo-request-notice'), isNotNull);
      friendships.onRespond = (_) async {
        profiles.friends = true;
        return FriendRequestResolution(
          request: request,
          status: FriendRequestStatus.accepted,
        );
      };
      await model.acceptFriendRequest();
      await drain();
      expect(
        inbox.notifications
            .firstWhere((n) => n.id == 'demo-request-notice')
            .requestStatus,
        FriendRequestStatus.accepted,
      );
      expect(inbox.errorFor('demo-request-notice'), isNull);
      model.dispose();
      inbox.dispose();
      await friendships.dispose();
    },
  );

  test(
    'Disposing a profile during acceptance cannot notify or reload it later',
    () async {
      final request = DemoFriendshipRepository.marcRequest(profileUser.id);
      final friendships = ControlledFriendshipRepository(request);
      final pending = Completer<FriendRequestResolution>();
      friendships.onRespond = (_) => pending.future;
      final profiles = _Profiles();
      final model = PublicProfileViewModel(
        userId: request.senderId,
        currentUserId: profileUser.id,
        repository: profiles,
        friendshipRepository: friendships,
      );
      await model.load();
      final reads = profiles.reads;
      final accepting = model.acceptFriendRequest();
      model.dispose();
      pending.complete(
        FriendRequestResolution(
          request: request,
          status: FriendRequestStatus.accepted,
        ),
      );
      await accepting;
      await drain();
      expect(profiles.reads, reads);
      await friendships.dispose();
    },
  );
}
