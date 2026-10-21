import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/presentation/formatters/notification_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notification_test_data.dart';

void main() {
  test('R13: reminders/recommendations have no friend; social event contexts require an actor', () {
    for (final type in [
      NotificationType.reminder,
      NotificationType.recommendation,
    ]) {
      expect(
        () => AppNotification.activity(
          id: 'id',
          type: type,
          receivedAt: notificationNow,
          activity: notificationActivity,
          person: notificationPerson,
        ),
        throwsArgumentError,
      );
    }
    for (final type in [
      NotificationType.friendEnrolled,
      NotificationType.activityPublished,
    ]) {
      expect(
        () => AppNotification.activity(
          id: 'id',
          type: type,
          receivedAt: notificationNow,
          activity: notificationActivity,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => AppNotification.activity(
        id: 'id',
        type: NotificationType.friendRequest,
        receivedAt: notificationNow,
        activity: notificationActivity,
      ),
      throwsArgumentError,
    );
  });

  test('Reading creates an immutable copy without accepting a request', () {
    final original = requestNotice();
    final read = original.markRead();
    expect(original.isRead, isFalse);
    expect(read.isRead, isTrue);
    expect(read.requestStatus, FriendRequestStatus.pending);
    expect(
      read.resolveRequest(FriendRequestStatus.accepted).requestStatus,
      FriendRequestStatus.accepted,
    );
    expect(
      () => read.resolveRequest(FriendRequestStatus.pending),
      throwsArgumentError,
    );
    expect(
      () => eventNotice().resolveRequest(FriendRequestStatus.accepted),
      throwsArgumentError,
    );
  });

  test('Date headings distinguish today, yesterday, month/year boundaries and older dates', () {
    expect(
      notificationDayLabel(DateTime(2026, 9, 27, 4), notificationNow),
      'Avui',
    );
    expect(
      notificationDayLabel(DateTime(2026, 9, 26, 23), notificationNow),
      'Ahir',
    );
    expect(
      notificationDayLabel(DateTime(2025, 12, 31), DateTime(2026, 1, 1)),
      'Ahir',
    );
    expect(
      notificationDayLabel(DateTime(2026, 4, 2), notificationNow),
      '2 d’abril de 2026',
    );
    expect(notificationTime(DateTime(2026, 9, 27, 9, 5)), '09.05 h');
    expect(
      notificationActivitySchedule(notificationActivity.startsAt),
      '26 de setembre de 2026 · 19.00 h',
    );
  });
}
