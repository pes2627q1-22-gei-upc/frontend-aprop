import 'dart:async';

import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/notifications/data/demo_notification_repository.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/presentation/view_models/notifications_view_model.dart';
import 'package:aprop/features/profile/data/demo_friendship_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_repository.dart';
import 'package:aprop/features/profile/data/demo_public_profile_repository.dart';
import 'package:aprop/features/profile/models/received_friend_request.dart';
import 'package:aprop/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:aprop/features/profile/presentation/view_models/public_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../notifications/fake_notification_repository.dart';
import 'friendship_test_support.dart';
import 'profile_test_data.dart';

Future<void> _drain() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late ControlledFriendshipRepository friendships;
  late PublicProfileViewModel peer;
  late NotificationsViewModel inbox;
  late ProfileViewModel own;
  var peerDisposed = false;
  setUp(() {
    peerDisposed = false;
    final activities = DemoActivityRepository();
    friendships = ControlledFriendshipRepository(
      DemoFriendshipRepository.marcRequest(profileUser.id),
    );
    peer = PublicProfileViewModel(
      userId: 'demo-person-marc',
      currentUserId: profileUser.id,
      friendshipRepository: friendships,
      repository: DemoPublicProfileRepository(
        activityRepository: activities,
        friendshipRepository: friendships,
        currentUserId: () => profileUser.id,
      ),
    );
    inbox = NotificationsViewModel(
      userId: profileUser.id,
      friendshipRepository: friendships,
      repository: DemoNotificationRepository(
        activityRepository: activities,
        friendshipRepository: friendships,
      ),
    );
    own = ProfileViewModel(
      user: profileUser,
      friendshipRepository: friendships,
      repository: DemoProfileRepository(activityRepository: activities),
    );
  });
  tearDown(() async {
    if (!peerDisposed) peer.dispose();
    inbox.dispose();
    own.dispose();
    await friendships.dispose();
  });
  Future<void> load() => Future.wait([peer.load(), inbox.load(), own.load()]);

  for (final fromInbox in [false, true]) {
    test(
      'Declining from ${fromInbox ? 'Avisos' : 'profile'} resolves both views without friendship or counter/privacy changes',
      () async {
        await load();
        final previous = own.profile;
        expect(peer.friendship, FriendshipAction.incoming);
        if (fromInbox) {
          await inbox.respond('demo-request-notice', accept: false);
        } else {
          await peer.rejectFriendRequest();
        }
        await _drain();
        expect(peer.friendship, FriendshipAction.add);
        expect(peer.friendRequestFeedback, 'Sol·licitud rebutjada');
        expect(peer.friendRequestError, isNull);
        expect(peer.profile!.profile.friendCount, 3);
        expect(peer.profile!.isFriend, isFalse);
        expect(peer.profile!.plansVisible, isFalse);
        expect(peer.pastPlans, isNull);
        expect(own.profile, same(previous));
        expect(
          inbox.notifications
              .firstWhere((n) => n.id == 'demo-request-notice')
              .requestStatus,
          FriendRequestStatus.rejected,
        );
        expect(friendships.writes, 1);
        await peer.load();
        await inbox.load();
        expect(peer.friendship, FriendshipAction.add);
        expect(peer.friendRequestFeedback, 'Sol·licitud rebutjada');
        expect(
          inbox.notifications
              .firstWhere((n) => n.id == 'demo-request-notice')
              .requestStatus,
          FriendRequestStatus.rejected,
        );
        expect(friendships.resolutions('another-account'), isEmpty);
      },
    );
  }

  test('A pending decline disables other profile actions and refresh; failure permits a real retry', () async {
    await load();
    final pending = Completer<FriendRequestResolution>();
    friendships.onRespond = (accept) {
      expect(accept, isFalse);
      return pending.future;
    };
    final reads = friendships.reads;
    final declining = peer.rejectFriendRequest();
    await peer.rejectFriendRequest();
    await peer.acceptFriendRequest();
    await peer.load();
    expect(peer.friendship, FriendshipAction.rejecting);
    expect(peer.friendRequestFeedback, isNull);
    expect(friendships.writes, 1);
    expect(friendships.reads, reads);
    expect(
      inbox.notifications
          .firstWhere((n) => n.id == 'demo-request-notice')
          .requestStatus,
      FriendRequestStatus.pending,
    );
    pending.completeError(StateError('offline'));
    await declining;
    expect(peer.friendship, FriendshipAction.incoming);
    expect(peer.friendRequestError, contains('rebutjar'));
    expect(peer.friendRequestFeedback, isNull);
    friendships.onRespond = null;
    await peer.rejectFriendRequest();
    await _drain();
    expect(peer.friendship, FriendshipAction.add);
    expect(peer.friendRequestError, isNull);
    expect(peer.friendRequestFeedback, 'Sol·licitud rebutjada');
    expect(friendships.writes, 2);
  });

  test('Competing accept/decline actions on two screens share the first server operation', () async {
    await load();
    final pending = Completer<FriendRequestResolution>();
    friendships.onRespond = (accept) {
      expect(accept, isFalse);
      return pending.future;
    };
    final declining = peer.rejectFriendRequest();
    final accepting = inbox.respond('demo-request-notice', accept: true);
    await _drain();
    expect(friendships.writes, 1);
    pending.complete(
      FriendRequestResolution(
        request: friendships.request,
        status: FriendRequestStatus.rejected,
      ),
    );
    await Future.wait([declining, accepting]);
    await _drain();
    expect(peer.friendship, FriendshipAction.add);
    expect(peer.friendRequestFeedback, 'Sol·licitud rebutjada');
    expect(
      inbox.notifications
          .firstWhere((n) => n.id == 'demo-request-notice')
          .requestStatus,
      FriendRequestStatus.rejected,
    );
  });

  test(
    'A stale inbox reload cannot reintroduce actions after a profile decline',
    () async {
      await load();
      final notice = AppNotification.friendRequest(
        id: 'notice',
        receivedAt: friendships.request.sentAt,
        person: const NotificationPerson(
          id: 'demo-person-marc',
          name: 'Marc Vidal',
        ),
        requestId: friendships.request.id,
        isRead: true,
      );
      final repository = FakeNotificationRepository(
        inboxes: {
          profileUser.id: [notice],
        },
      );
      final staleInbox = NotificationsViewModel(
        userId: profileUser.id,
        repository: repository,
        friendshipRepository: friendships,
      );
      await staleInbox.load();
      final pending = Completer<List<AppNotification>>();
      repository.onLoad = (_) => pending.future;
      final loading = staleInbox.load();
      await peer.rejectFriendRequest();
      pending.complete([notice]);
      await loading;
      await _drain();
      expect(
        staleInbox.notifications.single.requestStatus,
        FriendRequestStatus.rejected,
      );
      staleInbox.dispose();
    },
  );

  test(
    'Declining from the profile clears an earlier inbox response error',
    () async {
      await load();
      friendships.onRespond = (_) async => throw StateError('offline');
      await inbox.respond('demo-request-notice', accept: false);
      expect(inbox.errorFor('demo-request-notice'), isNotNull);
      friendships.onRespond = null;
      await peer.rejectFriendRequest();
      await _drain();
      expect(inbox.errorFor('demo-request-notice'), isNull);
      expect(
        inbox.notifications
            .firstWhere((n) => n.id == 'demo-request-notice')
            .requestStatus,
        FriendRequestStatus.rejected,
      );
    },
  );

  test('Disposal during decline ignores late notifications but keeps the confirmed shared outcome', () async {
    await load();
    final pending = Completer<FriendRequestResolution>();
    friendships.onRespond = (_) => pending.future;
    final declining = peer.rejectFriendRequest();
    peer.dispose();
    peerDisposed = true;
    final reads = friendships.reads;
    pending.complete(
      FriendRequestResolution(
        request: friendships.request,
        status: FriendRequestStatus.rejected,
      ),
    );
    await declining;
    await _drain();
    expect(friendships.reads, reads);
    expect(
      inbox.notifications
          .firstWhere((n) => n.id == 'demo-request-notice')
          .requestStatus,
      FriendRequestStatus.rejected,
    );
  });
  test(
    'A prior outgoing hint is cleared after declining an incoming request',
    () async {
      friendships.onFetch = () async => [];
      await peer.load();
      await peer.sendFriendRequest();
      expect(peer.friendship, FriendshipAction.requestSent);
      friendships.onFetch = null;
      await peer.load();
      expect(peer.friendship, FriendshipAction.incoming);
      await peer.rejectFriendRequest();
      await _drain();
      expect(peer.friendship, FriendshipAction.add);
      expect(peer.friendRequestFeedback, 'Sol·licitud rebutjada');
    },
  );

  test('A decline joining an earlier inbox acceptance reports the confirmed accepted result', () async {
    await load();
    final pending = Completer<FriendRequestResolution>();
    friendships.onRespond = (accept) {
      expect(accept, isTrue);
      return pending.future;
    };
    final accepting = inbox.respond('demo-request-notice', accept: true);
    await _drain();
    final declining = peer.rejectFriendRequest();
    expect(friendships.writes, 1);
    pending.complete(
      FriendRequestResolution(
        request: friendships.request,
        status: FriendRequestStatus.accepted,
      ),
    );
    await Future.wait([accepting, declining]);
    await _drain();
    expect(peer.friendship, FriendshipAction.friends);
    expect(peer.friendRequestFeedback, isNull);
    expect(peer.friendRequestError, isNull);
    expect(
      inbox.notifications
          .firstWhere((n) => n.id == 'demo-request-notice')
          .requestStatus,
      FriendRequestStatus.accepted,
    );
  });
}
