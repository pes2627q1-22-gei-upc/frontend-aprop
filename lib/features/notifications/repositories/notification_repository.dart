import '../models/app_notification.dart';

abstract interface class NotificationRepository {
  /// Received inbox only, never scheduled future reminders. Throws on failure.
  Future<List<AppNotification>> getNotifications(String userId);

  /// Idempotent; completes only after persisting the read flag.
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  });

  /// Returns the confirmed outcome, including an already resolved request.
  /// The backend must authorize the recipient and establish mutual friendship
  /// atomically when accepting. Throws on failure; never returns pending.
  Future<FriendRequestStatus> respondToFriendRequest({
    required String userId,
    required String requestId,
    required bool accept,
  });
}
