import '../../../core/network/api_client.dart';
import '../../activities/models/activity.dart';
import '../../activities/repositories/activity_details_repository.dart';
import '../models/app_notification.dart';
import '../../profile/models/received_friend_request.dart';
import '../../profile/repositories/friendship_repository.dart';
import '../repositories/notification_repository.dart';
import 'notification_json_mapper.dart';

/// Received inbox and confirmed reads using the authenticated profile's UUID.
/// No synthetic user IDs or simulated social mutations.
class HttpNotificationRepository implements NotificationRepository {
  HttpNotificationRepository({
    required this.apiClient,
    required this.activityRepository,
    this.friendshipRepository,
  });
  final FriendshipRepository? friendshipRepository;
  final ApiClient apiClient;
  final ActivityDetailsRepository activityRepository;

  Future<({String id, Map<String, String> headers})> _sessionFor(
    String accountId,
  ) async {
    if (accountId.isEmpty) throw ArgumentError.value(accountId, 'userId');
    // Freeze one authenticated context for this operation. A response from a
    // different signed-in account cannot resolve this caller's inbox.
    final headers = Map<String, String>.unmodifiable(
      await apiClient.buildHeaders(),
    );
    if (!RegExp(r'^Bearer \S+$').hasMatch(headers['Authorization'] ?? '')) {
      throw ApiException(
        'Cal iniciar sessió per consultar els avisos.',
        statusCode: 401,
      );
    }
    final profile = await apiClient.getJson('users/me', headers: headers);
    if (profile is! Map<String, Object?>) {
      throw const FormatException('Expected the authenticated user profile');
    }
    final id = notificationUserId(profile['id']);
    final matchesUuid = accountId.toLowerCase() == id;
    if (!matchesUuid && profile['firebase-uid'] != accountId) {
      throw ApiException(
        'La sessió ha canviat. Torna a carregar els avisos.',
        statusCode: 401,
      );
    }
    return (id: id, headers: headers);
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    final session = await _sessionFor(userId);
    final decoded = await apiClient.getJson(
      'notifications/user/${session.id}',
      headers: session.headers,
    );
    if (decoded is! List<Object?>) {
      throw const FormatException('Expected a notification list');
    }
    final records = <NotificationRecord>[
      for (final row in decoded)
        if (row is Map<String, Object?>)
          NotificationRecord.fromJson(row, ownerId: session.id)
        else
          throw const FormatException('Expected a notification object'),
    ];
    final friends = friendshipRepository;
    final requests = friends == null
        ? const <ReceivedFriendRequest>[]
        : await friends.getReceivedRequests(userId);
    final resolutions =
        friends?.resolutions(userId) ?? const <FriendRequestResolution>[];
    final known = <String, ReceivedFriendRequest>{
      for (final r in requests) r.id: r,
      for (final r in resolutions) r.request.id: r.request,
    };
    if (records.isEmpty && known.isEmpty) return const [];
    if (records.map((record) => record.id).toSet().length != records.length) {
      throw const FormatException('Duplicate received notification ID');
    }
    final types = records.isEmpty
        ? const <String, NotificationType>{}
        : notificationTypesFromJson(
            await apiClient.getJson(
              'notificationtypes',
              headers: session.headers,
            ),
          );
    final activities = <String, ({Activity? activity, bool missing})>{};
    final people = <String, NotificationPerson>{};
    final jobs = <Future<void> Function()>[
      for (final id in records.map((r) => r.activityId).nonNulls.toSet())
        () async {
          try {
            final activity = await activityRepository.getActivityById(id);
            activities[id] = (activity: activity, missing: activity == null);
          } catch (error) {
            if (error is ApiException && error.statusCode == 401) rethrow;
            activities[id] = (activity: null, missing: false);
          }
        },
      for (final id in {
        ...records
            .where((r) => types[r.typeId] == NotificationType.socialUpdate)
            .map((r) => r.personId)
            .nonNulls,
        ...known.values.map((r) => r.senderId),
      })
        () async {
          var name = 'Una persona';
          try {
            final profile = await apiClient.getJson(
              'users/$id',
              headers: session.headers,
            );
            if (profile is Map<String, Object?> &&
                notificationUserId(profile['id']) == id) {
              for (final field in ['name', 'username']) {
                if (profile[field] case final String value
                    when value.trim().isNotEmpty) {
                  name = value.trim();
                  break;
                }
              }
            }
          } catch (error) {
            if (error is ApiException && error.statusCode == 401) rethrow;
            // A deleted or unavailable actor does not delete a received notice.
          }
          people[id] = NotificationPerson(id: id, name: name);
        },
    ];
    // Resolve each unique reference once per refresh, with a shared limit.
    for (var offset = 0; offset < jobs.length; offset += 4) {
      await Future.wait(jobs.skip(offset).take(4).map((job) => job()));
    }
    final matched = <String>{};
    final result = <AppNotification>[];
    for (final record in records) {
      final request = types[record.typeId] == NotificationType.socialUpdate
          ? known.values
                .where(
                  (r) =>
                      r.senderId == record.personId &&
                      r.sentAt == record.requestDate,
                )
                .firstOrNull
          : null;
      if (request != null) {
        matched.add(request.id);
        result.add(
          _requestNotice(
            request,
            resolutions,
            people[request.senderId]!,
            id: record.id,
            isRead: record.isRead,
          ),
        );
      } else {
        // TODO(DP-070): Social has no structured acceptance subtype. Keep it
        // generic; neither free text nor current friendship proves this event.
        result.add(
          AppNotification.received(
            id: record.id,
            receivedAt: record.receivedAt,
            isRead: record.isRead,
            type: types[record.typeId] ?? NotificationType.other,
            activityId: record.activityId,
            activity: activities[record.activityId]?.activity,
            activityUnavailable:
                activities[record.activityId]?.missing ?? false,
            person: types[record.typeId] == NotificationType.socialUpdate
                ? people[record.personId]
                : null,
          ),
        );
      }
    }
    // TODO(DP-066): sending a request currently creates no DB notification.
    // These cards come from the received-requests API. They have no persisted
    // unread receipt and must never call /notifications/{id}/read.
    for (final request in known.values.where((r) => !matched.contains(r.id))) {
      result.add(
        _requestNotice(
          request,
          resolutions,
          people[request.senderId]!,
          id: 'friend-request:${request.id}',
          isRead: true,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  AppNotification _requestNotice(
    ReceivedFriendRequest request,
    List<FriendRequestResolution> resolutions,
    NotificationPerson person, {
    required String id,
    required bool isRead,
  }) => AppNotification.friendRequest(
    id: id,
    receivedAt: request.sentAt,
    person: person,
    requestId: request.id,
    status:
        resolutions
            .where((r) => r.request.id == request.id)
            .firstOrNull
            ?.status ??
        FriendRequestStatus.pending,
    isRead: isRead,
  );

  @override
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    final id = int.tryParse(notificationId);
    if (id == null || id < 1) {
      throw ArgumentError.value(notificationId, 'notificationId');
    }
    final session = await _sessionFor(userId);
    // TODO(DP-039): The server must also enforce recipient ownership. This
    // check prevents accidental writes but does not replace server security.
    final decoded = await apiClient.getJson(
      'notifications/$id',
      headers: session.headers,
    );
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Expected a notification object');
    }
    final notice = NotificationRecord.fromJson(decoded, ownerId: session.id);
    if (notice.id != '$id') {
      throw const FormatException('Unexpected notification ID');
    }
    if (notice.isRead) return;
    await apiClient.postJson(
      'notifications/$id/read',
      headers: session.headers,
    );
  }

  Future<void> markAllAsRead(String userId) async {
    final session = await _sessionFor(userId);
    await apiClient.postJson(
      'notifications/user/${session.id}/read',
      headers: session.headers,
    );
  }

  @override
  Future<FriendRequestStatus> respondToFriendRequest({
    required String userId,
    required String requestId,
    required bool accept,
  }) async {
    final repository = friendshipRepository;
    if (repository == null) {
      throw UnsupportedError('Friendship repository unavailable');
    }
    return (await repository.respond(
      userId: userId,
      requestId: requestId,
      accept: accept,
    )).status;
  }
}
