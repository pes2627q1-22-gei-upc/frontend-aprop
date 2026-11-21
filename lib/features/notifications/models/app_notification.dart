import '../../activities/models/activity.dart';
import '../../profile/models/received_friend_request.dart';
export '../../profile/models/received_friend_request.dart'
    show FriendRequestStatus;

enum NotificationCategory { social, reminders, recommendations }

/// Client inbox projection, not a declaration of backend/UML enum values.
enum NotificationType {
  activityPublished,
  friendRequest,
  friendRequestAccepted,
  friendEnrolled,
  reminder,
  recommendation,
  socialUpdate,

  /// An activity the person joined was cancelled by its creator (#47).
  activityCancelled,
  other;

  NotificationCategory? get category => switch (this) {
    // TODO(DP-071): no filter of the mockup is for cancellations; they are
    // about the person's plans, like the reminders.
    reminder || activityCancelled => NotificationCategory.reminders,
    recommendation => NotificationCategory.recommendations,
    other => null,
    _ => NotificationCategory.social,
  };
}

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
    this.relatedActivityId,
    this.activityUnavailable = false,
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
        type == NotificationType.friendRequestAccepted ||
        type == NotificationType.socialUpdate ||
        type == NotificationType.other) {
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

  /// A received backend notice. A broad social category does not imply a
  /// friendship action; missing context must not delete the received notice.
  factory AppNotification.received({
    required String id,
    required NotificationType type,
    required DateTime receivedAt,
    required bool isRead,
    Activity? activity,
    String? activityId,
    NotificationPerson? person,
    bool activityUnavailable = false,
  }) {
    if (!{
      NotificationType.reminder,
      NotificationType.recommendation,
      NotificationType.socialUpdate,
      NotificationType.activityCancelled,
      NotificationType.other,
    }.contains(type)) {
      throw ArgumentError(
        'A backend category does not identify a social action.',
      );
    }
    if (activityUnavailable && (activityId == null || activity != null)) {
      throw ArgumentError(
        'An unavailable activity needs its original reference.',
      );
    }
    if ((type == NotificationType.reminder ||
            type == NotificationType.recommendation ||
            type == NotificationType.activityCancelled) &&
        person != null) {
      throw ArgumentError(
        'Reminders and recommendations do not have an actor.',
      );
    }
    if (activity != null && activityId != null && activity.id != activityId) {
      throw ArgumentError(
        'Activity context must match its received reference.',
      );
    }
    return AppNotification._(
      id: id,
      type: type,
      receivedAt: receivedAt,
      isRead: isRead,
      activity: activity,
      relatedActivityId: activityId,
      activityUnavailable: activityUnavailable,
      person: person,
    );
  }

  final String id;
  final NotificationType type;
  final DateTime receivedAt;
  final bool isRead;
  final Activity? activity;
  final String? relatedActivityId;
  final bool activityUnavailable;

  String? get activityId => activity?.id ?? relatedActivityId;
  bool get canOpenActivity => activityId != null && !activityUnavailable;

  /// Publisher, requesting person, accepting person or enrolled friend.
  /// This is display context, not the UML's optional `amic` relationship.
  final NotificationPerson? person;
  final String? requestId;
  final FriendRequestStatus? requestStatus;

  NotificationCategory? get category => type.category;

  AppNotification markRead() => _copy(isRead: true);

  AppNotification resolveRequest(
    FriendRequestStatus status, {
    bool markRead = true,
  }) {
    if (type != NotificationType.friendRequest ||
        status == FriendRequestStatus.pending) {
      throw ArgumentError('Only a received request can be resolved.');
    }
    return _copy(isRead: markRead ? true : isRead, requestStatus: status);
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
        relatedActivityId: relatedActivityId,
        activityUnavailable: activityUnavailable,
      );
}
