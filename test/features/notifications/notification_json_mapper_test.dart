import 'package:aprop/features/notifications/data/notification_json_mapper.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/presentation/formatters/notification_formatter.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backend_notification_fixture.dart';
import 'notification_test_data.dart';

void main() {
  test('Required fields never become invented IDs, dates or unread flags', () {
    for (final patch in <Map<String, Object?>>[
      {'id': null},
      {'id': -1},
      {'type': '19'},
      {'read': null},
      {'notification-date': 'not-a-date'},
      {'notification-date': '0001-01-01T00:00:00'},
      {'friend-id': 12},
      {'event': 0},
      {'user-id': 1},
    ]) {
      expect(
        () => NotificationRecord.fromJson({
          ...backendNotification(1),
          ...patch,
        }, ownerId: backendUserId),
        throwsFormatException,
      );
    }
  });

  test(
    'Received timestamps retain explicit offsets and zone-less calendar fields',
    () {
      final zoned = NotificationRecord.fromJson({
        ...backendNotification(1),
        'notification-date': '2026-10-26T13:05:00+02:00',
      }, ownerId: backendUserId);
      expect(zoned.receivedAt, DateTime.utc(2026, 10, 26, 11, 5));
      final local = NotificationRecord.fromJson(
        backendNotification(1),
        ownerId: backendUserId,
      );
      expect(local.receivedAt, DateTime(2026, 10, 26, 10, 5));
    },
  );

  test(
    'Type metadata must be valid; category spelling is independent of IDs',
    () {
      for (final payload in [
        null,
        {},
        [null],
        [
          {'id': 1},
        ],
        [
          {'id': 1, 'name': 'Social'},
          {'id': 1, 'name': 'Recordatori'},
        ],
      ]) {
        expect(() => notificationTypesFromJson(payload), throwsFormatException);
      }
      final types = notificationTypesFromJson([
        {'id': 92, 'name': ' Recomanació '},
        {'id': 18, 'name': 'SOCIAL'},
      ]);
      expect(types['92'], NotificationType.recommendation);
      expect(types['18'], NotificationType.socialUpdate);
      expect(() => types.clear(), throwsUnsupportedError);
    },
  );

  test('Generic notices preserve missing context through a confirmed read', () {
    final original = AppNotification.received(
      id: '1',
      type: NotificationType.reminder,
      receivedAt: notificationNow,
      isRead: false,
      activityId: '7',
      activityUnavailable: true,
    );
    final read = original.markRead();
    expect(original.isRead, isFalse);
    expect(read.isRead, isTrue);
    expect(read.activityId, '7');
    expect(read.activityUnavailable, isTrue);
    expect(read.canOpenActivity, isFalse);
    expect(notificationMessage(read), 'Tens un recordatori cultural.');
    expect(
      notificationActivitySchedule(
        Activity(
          id: 'unknown',
          title: 'Concert',
          category: 'Música',
          municipality: 'Manresa',
          startsAt: DateTime(1),
          imageAsset: 'assets/images/jazz_al_parc.jpg',
          source: ActivitySource.culturalAgenda,
        ),
      ),
      'Data no informada',
    );
    expect(
      () => original.resolveRequest(FriendRequestStatus.accepted),
      throwsArgumentError,
    );
  });

  test('A broad backend category cannot manufacture a social action or mismatched context', () {
    expect(
      () => AppNotification.received(
        id: '1',
        type: NotificationType.friendRequest,
        receivedAt: notificationNow,
        isRead: false,
      ),
      throwsArgumentError,
    );
    expect(
      () => AppNotification.received(
        id: '1',
        type: NotificationType.reminder,
        receivedAt: notificationNow,
        isRead: false,
        person: notificationPerson,
      ),
      throwsArgumentError,
    );
    expect(
      () => AppNotification.received(
        id: '1',
        type: NotificationType.recommendation,
        receivedAt: notificationNow,
        isRead: false,
        activity: notificationActivity,
        activityId: 'different',
      ),
      throwsArgumentError,
    );
  });
}
