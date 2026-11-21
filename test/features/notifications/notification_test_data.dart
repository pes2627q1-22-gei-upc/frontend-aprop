import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';

final notificationNow = DateTime(2026, 9, 27, 19, 5);
const notificationPerson = NotificationPerson(
  id: 'person-marc',
  name: 'Marc Vidal',
);
final notificationActivity = Activity(
  id: 'demo-jazz',
  title: 'Jazz al parc',
  category: 'Música',
  municipality: 'Barcelona',
  startsAt: DateTime(2026, 9, 26, 19),
  imageAsset: 'assets/images/jazz_al_parc.jpg',
  source: ActivitySource.culturalAgenda,
);

AppNotification acceptedFriendNotice({
  String id = 'accepted',
  DateTime? receivedAt,
  NotificationPerson person = notificationPerson,
  bool isRead = false,
}) => AppNotification.friendRequestAccepted(
  id: id,
  receivedAt: receivedAt ?? DateTime(2026, 9, 27, 18),
  person: person,
  isRead: isRead,
);

AppNotification requestNotice({String id = 'request', bool isRead = false}) =>
    AppNotification.friendRequest(
      id: id,
      receivedAt: DateTime(2026, 9, 27, 18),
      person: notificationPerson,
      requestId: 'request-marc',
      isRead: isRead,
    );

AppNotification eventNotice({
  String id = 'recommendation',
  NotificationType type = NotificationType.recommendation,
  DateTime? receivedAt,
  bool isRead = false,
}) => AppNotification.activity(
  id: id,
  type: type,
  receivedAt: receivedAt ?? DateTime(2026, 9, 27, 17),
  activity: notificationActivity,
  isRead: isRead,
  person:
      type == NotificationType.friendEnrolled ||
          type == NotificationType.activityPublished
      ? notificationPerson
      : null,
);
