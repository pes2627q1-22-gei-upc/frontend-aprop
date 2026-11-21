import '../../activities/repositories/activity_repository.dart';
import '../models/app_notification.dart';
import '../../profile/repositories/friendship_repository.dart';
import '../repositories/notification_repository.dart';

/// Historical mockup fixtures, isolated per demo account and lost on restart.
/// TODO(DP-023): Replace with authenticated inbox/friendship API adapters.
class DemoNotificationRepository implements NotificationRepository {
  DemoNotificationRepository({
    required this.activityRepository,
    this.friendshipRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ActivityRepository activityRepository;
  final FriendshipRepository? friendshipRepository;
  final DateTime Function() _now;
  final Map<String, List<AppNotification>> _inboxes = {};
  final Map<String, Future<List<AppNotification>>> _loading = {};

  Future<List<AppNotification>> _inbox(String userId) async {
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');
    final existing = _inboxes[userId];
    if (existing != null) return existing;
    final pending = _loading.putIfAbsent(userId, () => _createFixtures(userId));
    try {
      final notices = await pending;
      return _inboxes.putIfAbsent(userId, () => notices);
    } finally {
      if (identical(_loading[userId], pending)) _loading.remove(userId);
    }
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    final inbox = await _inbox(userId);
    final now = _now();
    final resolutions = friendshipRepository?.resolutions(userId) ?? const [];
    return List.unmodifiable(
      inbox.where((n) => !n.receivedAt.isAfter(now)).map((n) {
        final resolved = resolutions
            .where((r) => r.request.id == n.requestId)
            .firstOrNull;
        return resolved == null
            ? n
            : n.resolveRequest(resolved.status, markRead: false);
      }),
    );
  }

  @override
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    final inbox = await _inbox(userId);
    final index = inbox.indexWhere((n) => n.id == notificationId);
    if (index < 0 || inbox[index].receivedAt.isAfter(_now())) {
      throw StateError('Received notification not found.');
    }
    inbox[index] = inbox[index].markRead();
  }

  @override
  Future<FriendRequestStatus> respondToFriendRequest({
    required String userId,
    required String requestId,
    required bool accept,
  }) async {
    final inbox = await _inbox(userId);
    final index = inbox.indexWhere((n) => n.requestId == requestId);
    if (index < 0 || inbox[index].receivedAt.isAfter(_now())) {
      throw StateError('Received friendship request not found.');
    }
    final notice = inbox[index];
    if (notice.person!.id == userId) {
      throw StateError('R2: a user cannot respond to their own request.');
    }
    final friends = friendshipRepository;
    final status = friends != null
        ? (await friends.respond(
            userId: userId,
            requestId: requestId,
            accept: accept,
          )).status
        : notice.requestStatus == FriendRequestStatus.pending
        ? (accept ? FriendRequestStatus.accepted : FriendRequestStatus.rejected)
        : notice.requestStatus!;
    for (var i = 0; i < inbox.length; i++) {
      if (inbox[i].requestId == requestId) {
        inbox[i] = inbox[i].resolveRequest(status);
      }
    }
    return status;
  }

  Future<List<AppNotification>> _createFixtures(String userId) async {
    final activities = {
      for (final activity in await activityRepository.getActivities())
        activity.id: activity,
    };
    const laia = NotificationPerson(
      id: 'demo-person-laia',
      name: 'Laia Soler',
      avatarAsset: 'assets/images/laia_soler.jpg',
    );
    const marc = NotificationPerson(id: 'demo-person-marc', name: 'Marc Vidal');
    const julia = NotificationPerson(
      id: 'demo-person-julia',
      name: 'Júlia Riera',
    );
    final friendships = friendshipRepository;
    final pendingRequests =
        await friendships?.getReceivedRequests(userId) ?? const [];
    final marcRequest =
        pendingRequests.where((r) => r.senderId == marc.id).firstOrNull ??
        friendships
            ?.resolutions(userId)
            .where((r) => r.request.senderId == marc.id)
            .firstOrNull
            ?.request;
    final notices = <AppNotification>[
      if (friendships == null || marcRequest != null)
        AppNotification.friendRequest(
          id: 'demo-request-notice',
          receivedAt: DateTime(2026, 9, 26, 16, 30),
          person: marc,
          requestId: marcRequest?.id ?? 'demo-request-marc',
        ),
      AppNotification.friendRequestAccepted(
        id: 'demo-friend-accepted',
        receivedAt: DateTime(2026, 9, 26, 15, 20),
        person: julia,
        isRead: true,
      ),
    ];
    void addActivity(
      String id,
      String activityId,
      NotificationType type,
      DateTime receivedAt, {
      bool isRead = false,
      NotificationPerson? person,
    }) {
      final activity = activities[activityId];
      if (activity == null) return;
      notices.add(
        AppNotification.activity(
          id: id,
          type: type,
          receivedAt: receivedAt,
          activity: activity,
          person: person,
          isRead: isRead,
        ),
      );
    }

    addActivity(
      'demo-reminder-jazz',
      'demo-jazz',
      NotificationType.reminder,
      DateTime(2026, 9, 26, 18),
    );
    addActivity(
      'demo-published-theatre',
      'demo-theatre',
      NotificationType.activityPublished,
      DateTime(2026, 9, 26, 17, 45),
      person: laia,
    );
    addActivity(
      'demo-recommendation-exhibition',
      'demo-exhibition',
      NotificationType.recommendation,
      DateTime(2026, 9, 26, 17, 10),
      isRead: true,
    );
    addActivity(
      'demo-recommendation-theatre',
      'demo-theatre',
      NotificationType.recommendation,
      DateTime(2026, 9, 26, 17, 55),
    );
    addActivity(
      'demo-friend-jazz',
      'demo-jazz',
      NotificationType.friendEnrolled,
      DateTime(2026, 9, 26, 14, 40),
      person: laia,
      isRead: true,
    );
    addActivity(
      'demo-reminder-theatre',
      'demo-theatre',
      NotificationType.reminder,
      DateTime(2026, 9, 27, 19),
    );
    addActivity(
      'demo-reminder-exhibition',
      'demo-exhibition',
      NotificationType.reminder,
      DateTime(2026, 9, 27, 9),
      isRead: true,
    );
    return notices;
  }
}
