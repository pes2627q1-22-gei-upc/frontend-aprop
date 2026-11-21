import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/notifications/data/http_notification_repository.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/presentation/view_models/notifications_view_model.dart';
import 'package:aprop/features/profile/data/http_friendship_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import '../activities/fake_activity_repository.dart';
import '../profile/backend_profile_fixture.dart';
import '../profile/backend_friend_request_fixture.dart';
import 'backend_notification_fixture.dart';

void main() {
  for (final hasNotice in [false, true]) {
    test(
      'HTTP decline ${hasNotice ? 'with' : 'without'} a DB notice uses the exact request and survives a read failure',
      () async {
        var resolved = false;
        var denials = 0;
        var reads = 0;
        final client = ApiClient(
          idToken: () async => 'test-token',
          client: MockClient((r) async {
            if (r.url.path == '/users/me') {
              return jsonResponse(backendProfile());
            }
            if (r.url.path == '/users/me/friend-requests') {
              return jsonResponse(resolved ? [] : [requestJson()]);
            }
            if (r.url.path == '/notifications/user/$profileServerId') {
              return jsonResponse(
                hasNotice
                    ? [
                        {
                          ...backendNotification(7, type: 41, event: null),
                          'friend-id': otherProfileServerId,
                          'request-date': sent,
                        },
                      ]
                    : [],
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
            if (r.method == 'POST' && r.url.path.endsWith('/deny')) {
              expect(r.url.pathSegments, [
                'users',
                otherProfileServerId,
                'friend-requests',
                sent,
                'deny',
              ]);
              denials++;
              resolved = true;
              return jsonResponse(requestJson(state: 'Rejected'));
            }
            if (r.url.path == '/notifications/7') {
              return jsonResponse({
                ...backendNotification(7, type: 41, event: null),
                'friend-id': otherProfileServerId,
                'request-date': sent,
              });
            }
            if (r.url.path == '/notifications/7/read') {
              reads++;
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
        final id = model.notifications.single.id;
        await model.respond(id, accept: false);
        expect(denials, 1);
        expect(reads, hasNotice ? 1 : 0);
        expect(
          model.notifications.single.requestStatus,
          FriendRequestStatus.rejected,
        );
        if (hasNotice) {
          expect(model.errorFor(id), contains('marcar'));
        } else {
          expect(model.errorFor(id), isNull);
        }
        await model.load();
        expect(
          model.notifications.single.requestStatus,
          FriendRequestStatus.rejected,
        );
        await model.respond(id, accept: true);
        expect(denials, 1);
        model.dispose();
        await friendships.dispose();
      },
    );
  }

  for (final incorrectState in ['Accepted', 'Pending']) {
    test(
      'A deny response with $incorrectState is not confirmed locally',
      () async {
        final client = ApiClient(
          idToken: () async => 'test-token',
          client: MockClient((r) async {
            if (r.url.path == '/users/me') {
              return jsonResponse(backendProfile());
            }
            if (r.method == 'GET') return jsonResponse([requestJson()]);
            return jsonResponse(requestJson(state: incorrectState));
          }),
        );
        final repository = HttpFriendshipRepository(apiClient: client);
        final request = (await repository.getReceivedRequests('user-a')).single;
        await expectLater(
          repository.respond(
            userId: 'user-a',
            requestId: request.id,
            accept: false,
          ),
          throwsFormatException,
        );
        expect(repository.resolutions('user-a'), isEmpty);
        await repository.dispose();
      },
    );
  }
}
