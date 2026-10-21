import 'dart:async';

import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/presentation/view_models/notifications_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_repository.dart';
import 'notification_test_data.dart';

void main() {
  late FakeNotificationRepository repository;
  late NotificationsViewModel vm;
  setUp(() {
    repository = FakeNotificationRepository(
      inboxes: {
        'user-a': [
          eventNotice(),
          requestNotice(),
          eventNotice(
            id: 'yesterday',
            type: NotificationType.reminder,
            receivedAt: DateTime(2026, 9, 26, 18),
            isRead: true,
          ),
          eventNotice(id: 'future', receivedAt: DateTime(2026, 9, 28)),
        ],
      },
    );
    vm = NotificationsViewModel(
      userId: 'user-a',
      repository: repository,
      now: () => notificationNow,
    );
  });
  tearDown(() => vm.dispose());

  test('Sorts received notices, excludes future schedules and exposes immutable data', () async {
    await vm.load();
    expect(vm.notifications.map((n) => n.id), [
      'request',
      'recommendation',
      'yesterday',
    ]);
    expect(() => vm.notifications.clear(), throwsUnsupportedError);
    expect(vm.hasLoaded, isTrue);
  });

  test(
    'Filtering does not mark notices read, resolve requests or fetch again',
    () async {
      await vm.load();
      for (final category in NotificationCategory.values) {
        vm.selectFilter(category);
        expect(
          vm.visibleNotifications.every((n) => n.category == category),
          isTrue,
        );
      }
      vm.selectFilter(null);
      expect(vm.visibleNotifications, hasLength(3));
      expect(vm.notifications.first.requestStatus, FriendRequestStatus.pending);
      expect(vm.notifications.first.isRead, isFalse);
      expect(repository.loads, ['user-a']);
      expect(repository.reads, isEmpty);
      expect(repository.responses, isEmpty);
    },
  );

  test(
    'Initial loading prevents duplicate loads and recovers after failure',
    () async {
      final pending = Completer<List<AppNotification>>();
      repository.onLoad = (_) => pending.future;
      final load = vm.load();
      await vm.load();
      expect(vm.isLoading, isTrue);
      expect(repository.loads, hasLength(1));
      pending.completeError(StateError('Offline'));
      await load;
      expect(vm.hasLoaded, isFalse);
      expect(vm.errorMessage, isNotNull);
      repository.onLoad = null;
      await vm.load();
      expect(vm.errorMessage, isNull);
      expect(vm.hasLoaded, isTrue);
    },
  );

  test('A failed refresh retains data and the selected filter', () async {
    await vm.load();
    vm.selectFilter(NotificationCategory.social);
    repository.onLoad = (_) async => throw StateError('Offline');
    await vm.load();
    expect(vm.visibleNotifications.single.id, 'request');
    expect(vm.errorMessage, isNotNull);
  });

  test('Reading waits for confirmation, prevents duplicate writes and does not accept', () async {
    await vm.load();
    final pending = Completer<void>();
    repository.onRead = () => pending.future;
    final reading = vm.markAsRead('request');
    expect(await vm.markAsRead('request'), isFalse);
    expect(vm.notifications.first.isRead, isFalse);
    expect(vm.isReading('request'), isTrue);
    pending.complete();
    expect(await reading, isTrue);
    expect(vm.notifications.first.isRead, isTrue);
    expect(vm.notifications.first.requestStatus, FriendRequestStatus.pending);
    expect(repository.reads, hasLength(1));
    expect(await vm.markAsRead('request'), isTrue);
    expect(repository.reads, hasLength(1));
  });

  test('Failed read stays unread and permits retry', () async {
    await vm.load();
    repository.onRead = () async => throw StateError('Offline');
    expect(await vm.markAsRead('request'), isFalse);
    expect(vm.notifications.first.isRead, isFalse);
    expect(vm.errorFor('request'), isNotNull);
    repository.onRead = null;
    expect(await vm.markAsRead('request'), isTrue);
    expect(vm.errorFor('request'), isNull);
  });

  for (final accept in [true, false]) {
    test(
      'Confirmed friendship response resolves and reads the notice: $accept',
      () async {
        await vm.load();
        final pending = Completer<FriendRequestStatus>();
        repository.onRespond = () => pending.future;
        final response = vm.respond('request', accept: accept);
        await vm.respond('request', accept: !accept);
        await vm.load();
        expect(
          vm.notifications.first.requestStatus,
          FriendRequestStatus.pending,
        );
        expect(repository.responses, hasLength(1));
        expect(repository.loads, hasLength(1));
        final status = accept
            ? FriendRequestStatus.accepted
            : FriendRequestStatus.rejected;
        pending.complete(status);
        await response;
        expect(vm.notifications.first.requestStatus, status);
        expect(vm.notifications.first.isRead, isTrue);
        await vm.respond('request', accept: !accept);
        expect(repository.responses, hasLength(1));
      },
    );
  }

  test(
    'Failed response stays pending and retries without losing read status',
    () async {
      await vm.load();
      await vm.markAsRead('request');
      repository.onRespond = () async => throw StateError('Offline');
      await vm.respond('request', accept: true);
      expect(vm.notifications.first.isRead, isTrue);
      expect(vm.notifications.first.requestStatus, FriendRequestStatus.pending);
      expect(vm.errorFor('request'), isNotNull);
      repository.onRespond = null;
      await vm.respond('request', accept: true);
      expect(
        vm.notifications.first.requestStatus,
        FriendRequestStatus.accepted,
      );
      expect(vm.errorFor('request'), isNull);
    },
  );

  test('An unconfirmed response is an error; an already resolved outcome is authoritative', () async {
    await vm.load();
    repository.onRespond = () async => FriendRequestStatus.pending;
    await vm.respond('request', accept: true);
    expect(vm.notifications.first.requestStatus, FriendRequestStatus.pending);
    expect(vm.errorFor('request'), isNotNull);
    repository.onRespond = () async => FriendRequestStatus.rejected;
    await vm.respond('request', accept: true);
    expect(vm.notifications.first.requestStatus, FriendRequestStatus.rejected);
  });

  test('Reading and responding to one request cannot race', () async {
    await vm.load();
    final pending = Completer<void>();
    repository.onRead = () => pending.future;
    final read = vm.markAsRead('request');
    await vm.respond('request', accept: true);
    expect(repository.responses, isEmpty);
    pending.complete();
    await read;
  });

  for (final operation in ['load', 'read', 'respond']) {
    test('Late $operation completion after disposal does not notify', () async {
      final disposable = NotificationsViewModel(
        userId: 'user-a',
        repository: repository,
        now: () => notificationNow,
      );
      final completer = Completer<void>();
      if (operation != 'load') await disposable.load();
      repository.onLoad = (_) async {
        await completer.future;
        return [];
      };
      repository.onRead = () => completer.future;
      repository.onRespond = () async {
        await completer.future;
        return FriendRequestStatus.accepted;
      };
      var notifications = 0;
      disposable.addListener(() => notifications++);
      final Future<Object?> request = switch (operation) {
        'load' => disposable.load(),
        'read' => disposable.markAsRead('request'),
        _ => disposable.respond('request', accept: true),
      };
      disposable.dispose();
      completer.complete();
      await request;
      expect(notifications, 1);
    });
  }
}
