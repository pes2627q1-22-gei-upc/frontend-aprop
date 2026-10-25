import '../../../core/network/api_client.dart';
import '../../activities/repositories/activity_repository.dart';
import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

/// Implementació de [NotificationRepository] connectada al backend de Render
/// (`/notifications/user/{id}`, `/notifications/{id}/read`).
class HttpNotificationRepository implements NotificationRepository {
  HttpNotificationRepository({
    required this.apiClient,
    required this.activityRepository,
  });

  final ApiClient apiClient;
  final ActivityRepository activityRepository;
  final Map<String, int> _numericUserIds = {};
  final Map<String, FriendRequestStatus> _resolvedRequests = {};

  Future<int?> _resolveNumericUserId(String userId) async {
    final direct = int.tryParse(userId);
    if (direct != null) return direct;
    if (_numericUserIds.containsKey(userId)) return _numericUserIds[userId];

    try {
      final decoded = await apiClient.getJson('users/me');
      if (decoded is Map<String, Object?> && decoded['id'] is num) {
        final numericId = (decoded['id'] as num).toInt();
        _numericUserIds[userId] = numericId;
        return numericId;
      }
    } on ApiException {
      return null;
    }
    return null;
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');
    final numericId = await _resolveNumericUserId(userId);
    if (numericId == null) return const [];

    final decoded = await apiClient.getJson('notifications/user/$numericId');
    if (decoded is! List<Object?>) return const [];

    final notifications = <AppNotification>[];
    for (final item in decoded) {
      if (item is Map<String, Object?>) {
        final mapped = await _notificationFromJson(item);
        if (mapped != null) notifications.add(mapped);
      }
    }
    return List.unmodifiable(notifications);
  }

  @override
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await apiClient.postJson('notifications/$notificationId/read');
  }

  /// Marca totes les notificacions d'un usuari com a llegides (`POST /notifications/user/{id}/read`).
  Future<void> markAllAsRead(String userId) async {
    final numericId = await _resolveNumericUserId(userId);
    if (numericId == null) return;
    await apiClient.postJson('notifications/user/$numericId/read');
  }

  @override
  Future<FriendRequestStatus> respondToFriendRequest({
    required String userId,
    required String requestId,
    required bool accept,
  }) async {
    final existing = _resolvedRequests[requestId];
    if (existing != null && existing != FriendRequestStatus.pending) {
      return existing;
    }
    final status = accept
        ? FriendRequestStatus.accepted
        : FriendRequestStatus.rejected;
    _resolvedRequests[requestId] = status;
    return status;
  }

  Future<AppNotification?> _notificationFromJson(
    Map<String, Object?> json,
  ) async {
    final id = '${json['id']}';
    final isRead = json['read'] as bool? ?? false;
    final dateStr = json['notification-date'] as String?;
    final receivedAt = dateStr != null && dateStr.isNotEmpty
        ? DateTime.parse(dateStr)
        : DateTime.now();

    final typeCode = (json['type'] as num?)?.toInt() ?? 1;
    final friendId = json['friend-id'] ?? json['friend'];
    final eventId = json['event'];

    final person = friendId != null
        ? NotificationPerson(
            id: '$friendId',
            name: json['friend-name'] as String? ?? 'Usuari #$friendId',
          )
        : null;

    if (typeCode == 2 && person != null) {
      final requestId = 'req-$id';
      return AppNotification.friendRequest(
        id: id,
        receivedAt: receivedAt,
        person: person,
        requestId: requestId,
        status: _resolvedRequests[requestId] ?? FriendRequestStatus.pending,
        isRead: isRead,
      );
    }

    if (typeCode == 3 && person != null) {
      return AppNotification.friendRequestAccepted(
        id: id,
        receivedAt: receivedAt,
        person: person,
        isRead: isRead,
      );
    }

    if (eventId != null) {
      final activity = await activityRepository.getActivityById('$eventId');
      if (activity == null) return null;

      final type = switch (typeCode) {
        4 => NotificationType.friendEnrolled,
        5 => NotificationType.activityPublished,
        6 => NotificationType.recommendation,
        _ => NotificationType.reminder,
      };

      final needsPerson =
          type == NotificationType.friendEnrolled ||
          type == NotificationType.activityPublished;

      return AppNotification.activity(
        id: id,
        type: type,
        receivedAt: receivedAt,
        activity: activity,
        person: needsPerson
            ? (person ??
                  const NotificationPerson(id: 'unknown', name: 'Una amistat'))
            : null,
        isRead: isRead,
      );
    }

    return null;
  }
}
