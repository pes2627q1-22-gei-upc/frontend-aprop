import '../../activities/models/activity.dart';

enum NotificationCategory { social, reminders, recommendations }

/// Client inbox projection, not a declaration of backend/UML enum values.
enum NotificationType {
  activityPublished,
  friendRequest,
  friendRequestAccepted,
  friendEnrolled,
  reminder,
  recommendation;

  NotificationCategory get category => switch (this) {
    reminder => NotificationCategory.reminders,
    recommendation => NotificationCategory.recommendations,
    _ => NotificationCategory.social,
  };
}

enum FriendRequestStatus { pending, accepted, rejected }

class NotificationPerson {
  const NotificationPerson({
    required this.id,
    required this.name,
    this.avatarAsset,
  });

  final String id;
  final String name;
  final String? avatarAsset;
}

/// Immutable received notice. Reading and responding are separate states.
class AppNotification {
  const AppNotification._({
    required this.id,
    required this.type,
    required this.receivedAt,
    required this.isRead,
    this.activity,
    this.person,
    this.requestId,
    this.requestStatus,
  });

  factory AppNotification.activity({
    required String id,
    required NotificationType type,
    required DateTime receivedAt,
    required Activity activity,
    NotificationPerson? person,
    bool isRead = false,
  }) {
    if (type == NotificationType.friendRequest ||
        type == NotificationType.friendRequestAccepted) {
      throw ArgumentError('Friendship notices use their named constructors.');
    }
    final needsPerson =
        type == NotificationType.friendEnrolled ||
        type == NotificationType.activityPublished;
    if (needsPerson != (person != null)) {
      throw ArgumentError('Only social activity notices require an actor.');
    }
    return AppNotification._(
      id: id,
      type: type,
      receivedAt: receivedAt,
      activity: activity,
      person: person,
      isRead: isRead,
    );
  }

  factory AppNotification.friendRequest({
    required String id,
    required DateTime receivedAt,
    required NotificationPerson person,
    required String requestId,
    FriendRequestStatus status = FriendRequestStatus.pending,
    bool isRead = false,
  }) => AppNotification._(
    id: id,
    type: NotificationType.friendRequest,
    receivedAt: receivedAt,
    person: person,
    requestId: requestId,
    requestStatus: status,
    isRead: isRead,
  );

  factory AppNotification.friendRequestAccepted({
    required String id,
    required DateTime receivedAt,
    required NotificationPerson person,
    bool isRead = false,
  }) => AppNotification._(
    id: id,
    type: NotificationType.friendRequestAccepted,
    receivedAt: receivedAt,
    person: person,
    isRead: isRead,
  );

  final String id;
  final NotificationType type;
  final DateTime receivedAt;
  final bool isRead;
  final Activity? activity;

  /// Publisher, requesting person, accepting person or enrolled friend.
  /// This is display context, not the UML's optional `amic` relationship.
  final NotificationPerson? person;
  final String? requestId;
  final FriendRequestStatus? requestStatus;

  NotificationCategory get category => type.category;

  AppNotification markRead() => _copy(isRead: true);

  AppNotification resolveRequest(FriendRequestStatus status) {
    if (type != NotificationType.friendRequest ||
        status == FriendRequestStatus.pending) {
      throw ArgumentError('Only a received request can be resolved.');
    }
    return _copy(isRead: true, requestStatus: status);
  }

  AppNotification _copy({bool? isRead, FriendRequestStatus? requestStatus}) =>
      AppNotification._(
        id: id,
        type: type,
        receivedAt: receivedAt,
        isRead: isRead ?? this.isRead,
        activity: activity,
        person: person,
        requestId: requestId,
        requestStatus: requestStatus ?? this.requestStatus,
      );
}
