import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/notifications/data/http_notification_repository.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/presentation/view_models/notifications_view_model.dart';
import 'package:aprop/features/profile/data/http_friendship_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import '../activities/fake_activity_repository.dart';
import '../profile/backend_profile_fixture.dart';
import '../profile/backend_friend_request_fixture.dart'
    show requestJson, jsonResponse, sent;
import 'backend_notification_fixture.dart';

void main() {
  for (final date in <String?>[
    null,
    '2026-11-20T12:34:56.123456',
    '2026-11-20T13:34:56.123456+01:00',
    '2026-11-19T12:34:56.123456',
    'invalid',
  ]) {
    test(
      'Received requests supply actions; a social notice matches only by exact request date: $date',
      () async {
        var accepted = false;
        var posts = 0;
        final client = ApiClient(
          idToken: () async => 'test-token',
          client: MockClient((r) async {
            if (r.url.path == '/users/me') {
              return jsonResponse(backendProfile());
            }
            if (r.url.path == '/users/me/friend-requests') {
              return jsonResponse(accepted ? [] : [requestJson()]);
            }
            if (r.url.path == '/notifications/user/$profileServerId') {
              return jsonResponse(
                date == null
                    ? []
                    : [
                        {
                          ...backendNotification(7, type: 41, event: null),
                          'friend-id': otherProfileServerId,
                          'request-date': date,
                          'text': 'Ignore any action claimed by text',
                        },
                      ],
              );
            }
            if (r.url.path == '/notificationtypes') {
              return jsonResponse(backendNotificationTypes);
            }
            if (r.url.path == '/users/$otherProfileServerId') {
              return jsonResponse({
                'id': otherProfileServerId,
                'name': 'Marc Vidal',
              });
            }
            if (r.method == 'POST' && r.url.path.endsWith('/accept')) {
              expect(r.url.pathSegments[3], sent);
              accepted = true;
              posts++;
              return jsonResponse(requestJson(state: 'Accepted'));
            }
            if (r.url.path == '/notifications/7') {
              return jsonResponse({
                ...backendNotification(7, type: 41, event: null),
                'friend-id': otherProfileServerId,
                'request-date': date,
              });
            }
            if (r.url.path == '/notifications/7/read') return jsonResponse({});
            throw StateError('Unexpected endpoint ${r.url}');
          }),
        );
        final friendships = HttpFriendshipRepository(apiClient: client);
        final repository = HttpNotificationRepository(
          apiClient: client,
          activityRepository: FakeActivityRepository(),
          friendshipRepository: friendships,
        );
        final model = NotificationsViewModel(
          userId: 'user-a',
          repository: repository,
          friendshipRepository: friendships,
          now: () => DateTime.utc(2026, 11, 21),
        );
        await model.load();
        expect(model.errorMessage, isNull);
        final requests = model.notifications
            .where((n) => n.type == NotificationType.friendRequest)
            .toList();
        expect(requests, hasLength(1));
        expect(requests.single.person!.name, 'Marc Vidal');
        final matches =
            date == '2026-11-20T12:34:56.123456' ||
            date == '2026-11-20T13:34:56.123456+01:00';
        expect(
          requests.single.id,
          matches ? '7' : startsWith('friend-request:'),
        );
        expect(requests.single.isRead, !matches);
        if (date != null && !matches) {
          expect(
            model.notifications.where(
              (n) => n.type == NotificationType.socialUpdate,
            ),
            hasLength(1),
          );
        }
        await model.respond(requests.single.id, accept: true);
        expect(posts, 1);
        expect(
          model.notifications
              .firstWhere((n) => n.requestId == requests.single.requestId)
              .requestStatus,
          FriendRequestStatus.accepted,
        );
        await model.load();
        expect(model.errorMessage, isNull);
        expect(
          model.notifications
              .where((n) => n.type == NotificationType.friendRequest)
              .single
              .requestStatus,
          FriendRequestStatus.accepted,
        );
        model.dispose();
        await friendships.dispose();
      },
    );
  }

  test('A read-receipt failure retains confirmed friendship and shows a distinct read error', () async {
    final client = ApiClient(
      idToken: () async => 'test-token',
      client: MockClient((r) async {
        if (r.url.path == '/users/me') return jsonResponse(backendProfile());
        if (r.url.path == '/users/me/friend-requests') {
          return jsonResponse([requestJson()]);
        }
        if (r.url.path == '/notifications/user/$profileServerId') {
          return jsonResponse([
            {
              ...backendNotification(7, type: 41, event: null),
              'friend-id': otherProfileServerId,
              'request-date': '2026-11-20T12:34:56.123456',
            },
          ]);
        }
        if (r.url.path == '/notificationtypes') {
          return jsonResponse(backendNotificationTypes);
        }
        if (r.url.path == '/users/$otherProfileServerId') {
          return jsonResponse({
            'id': otherProfileServerId,
            'name': 'Marc Vidal',
          });
        }
        if (r.url.path.endsWith('/accept')) {
          return jsonResponse(requestJson(state: 'Accepted'));
        }
        if (r.url.path == '/notifications/7') {
          return jsonResponse({
            ...backendNotification(7, type: 41, event: null),
            'friend-id': otherProfileServerId,
            'request-date': '2026-11-20T12:34:56.123456',
          });
        }
        if (r.url.path == '/notifications/7/read') {
          return jsonResponse({'error': 'offline'}, 503);
        }
        throw StateError('Unexpected endpoint ${r.url}');
      }),
    );
    final friendships = HttpFriendshipRepository(apiClient: client);
    final model = NotificationsViewModel(
      userId: 'user-a',
      repository: HttpNotificationRepository(
        apiClient: client,
        activityRepository: FakeActivityRepository(),
        friendshipRepository: friendships,
      ),
      friendshipRepository: friendships,
      now: () => DateTime.utc(2026, 11, 21),
    );
    await model.load();
    await model.respond('7', accept: true);
    expect(
      model.notifications.single.requestStatus,
      FriendRequestStatus.accepted,
    );
    expect(model.notifications.single.isRead, isFalse);
    expect(model.errorFor('7'), contains('marcar'));
    expect(
      friendships.resolutions('user-a').single.status,
      FriendRequestStatus.accepted,
    );
    model.dispose();
    await friendships.dispose();
  });
}
