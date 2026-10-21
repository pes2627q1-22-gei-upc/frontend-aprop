import 'dart:async';

import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/notifications/data/demo_notification_repository.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notification_test_data.dart';

class _Catalogue extends DemoActivityRepository {
  Future<List<Activity>> Function()? onLoad;
  int requests = 0;
  @override
  Future<List<Activity>> getActivities() async {
    requests++;
    return onLoad?.call() ?? super.getActivities();
  }
}

void main() {
  late _Catalogue catalogue;
  late DemoNotificationRepository repository;
  setUp(() {
    catalogue = _Catalogue();
    repository = DemoNotificationRepository(
      activityRepository: catalogue,
      now: () => notificationNow,
    );
  });

  test(
    'Only received notices appear and historical read reminders remain visible',
    () async {
      final before = DemoNotificationRepository(
        activityRepository: catalogue,
        now: () => DateTime(2026, 9, 26, 18, 5),
      );
      final notices = await before.getNotifications('user-a');
      expect(notices.any((n) => n.id == 'demo-reminder-theatre'), isFalse);
      expect(notices.any((n) => n.id == 'demo-reminder-jazz'), isTrue);
      final later = await repository.getNotifications('user-a');
      expect(
        later.where((n) => n.type == NotificationType.reminder),
        hasLength(3),
      );
      expect(
        later.any((n) => n.id == 'demo-reminder-exhibition' && n.isRead),
        isTrue,
      );
      expect(() => later.clear(), throwsUnsupportedError);
    },
  );

  test(
    'Concurrent initialization shares one load without losing read updates',
    () async {
      final pending = Completer<List<Activity>>();
      catalogue.onLoad = () => pending.future;
      final first = repository.getNotifications('user-a');
      final second = repository.markAsRead(
        userId: 'user-a',
        notificationId: 'demo-request-notice',
      );
      pending.complete([]);
      await first;
      await second;
      expect(catalogue.requests, 1);
      expect(
        (await repository.getNotifications('user-a')).first.isRead,
        isTrue,
      );
    },
  );

  test('Failed initialization permits retry and missing catalogue events are omitted', () async {
    catalogue.onLoad = () async => throw StateError('Offline');
    await expectLater(repository.getNotifications('user-a'), throwsStateError);
    catalogue.onLoad = () async => [];
    final notices = await repository.getNotifications('user-a');
    expect(catalogue.requests, 2);
    expect(notices.every((n) => n.activity == null), isTrue);
  });

  test(
    'Read and request outcomes persist per account with first response winning',
    () async {
      await repository.markAsRead(
        userId: 'user-a',
        notificationId: 'demo-reminder-jazz',
      );
      final first = repository.respondToFriendRequest(
        userId: 'user-a',
        requestId: 'demo-request-marc',
        accept: true,
      );
      final repeated = repository.respondToFriendRequest(
        userId: 'user-a',
        requestId: 'demo-request-marc',
        accept: false,
      );
      expect(await first, FriendRequestStatus.accepted);
      expect(await repeated, FriendRequestStatus.accepted);
      final a = await repository.getNotifications('user-a');
      final b = await repository.getNotifications('user-b');
      expect(a.firstWhere((n) => n.id == 'demo-reminder-jazz').isRead, isTrue);
      expect(b.firstWhere((n) => n.id == 'demo-reminder-jazz').isRead, isFalse);
      expect(
        a.firstWhere((n) => n.requestId != null).requestStatus,
        FriendRequestStatus.accepted,
      );
      expect(
        b.firstWhere((n) => n.requestId != null).requestStatus,
        FriendRequestStatus.pending,
      );
    },
  );

  test(
    'Reading a request does not resolve it; rejecting persists the result',
    () async {
      await repository.markAsRead(
        userId: 'user-a',
        notificationId: 'demo-request-notice',
      );
      var request = (await repository.getNotifications('user-a'))
          .firstWhere((n) => n.requestId != null);
      expect(request.requestStatus, FriendRequestStatus.pending);
      await repository.respondToFriendRequest(
        userId: 'user-a',
        requestId: 'demo-request-marc',
        accept: false,
      );
      request = (await repository.getNotifications('user-a'))
          .firstWhere((n) => n.requestId != null);
      expect(request.requestStatus, FriendRequestStatus.rejected);
      expect(request.isRead, isTrue);
    },
  );

  test(
    'Unknown IDs, empty identity and future requests cannot be mutated',
    () async {
      await expectLater(
        repository.markAsRead(userId: 'user-a', notificationId: 'missing'),
        throwsStateError,
      );
      await expectLater(
        repository.respondToFriendRequest(
          userId: 'user-a',
          requestId: 'missing',
          accept: true,
        ),
        throwsStateError,
      );
      await expectLater(repository.getNotifications(''), throwsArgumentError);
      final before = DemoNotificationRepository(
        activityRepository: catalogue,
        now: () => DateTime(2026, 9, 26, 12),
      );
      await expectLater(
        before.respondToFriendRequest(
          userId: 'user-a',
          requestId: 'demo-request-marc',
          accept: true,
        ),
        throwsStateError,
      );
    },
  );

  test('R2: a demo actor cannot accept their own request', () async {
    await expectLater(
      repository.respondToFriendRequest(
        userId: 'demo-person-marc',
        requestId: 'demo-request-marc',
        accept: true,
      ),
      throwsStateError,
    );
  });
}
