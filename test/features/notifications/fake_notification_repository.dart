import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/repositories/notification_repository.dart';

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({Map<String, List<AppNotification>>? inboxes})
    : inboxes = inboxes ?? {};

  final Map<String, List<AppNotification>> inboxes;
  final loads = <String>[];
  final reads = <String>[];
  final responses = <String>[];
  Future<List<AppNotification>> Function(String userId)? onLoad;
  Future<void> Function()? onRead;
  Future<FriendRequestStatus> Function()? onRespond;

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    loads.add(userId);
    if (onLoad != null) return onLoad!(userId);
    return List.unmodifiable(inboxes[userId] ?? []);
  }

  @override
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    reads.add('$userId/$notificationId');
    await onRead?.call();
    inboxes[userId] = [
      for (final n in inboxes[userId] ?? <AppNotification>[])
        if (n.id == notificationId) n.markRead() else n,
    ];
  }

  @override
  Future<FriendRequestStatus> respondToFriendRequest({
    required String userId,
    required String requestId,
    required bool accept,
  }) async {
    responses.add('$userId/$requestId/$accept');
    final status =
        await onRespond?.call() ??
        (accept ? FriendRequestStatus.accepted : FriendRequestStatus.rejected);
    if (status != FriendRequestStatus.pending) {
      inboxes[userId] = [
        for (final n in inboxes[userId] ?? <AppNotification>[])
          if (n.requestId == requestId) n.resolveRequest(status) else n,
      ];
    }
    return status;
  }
}
