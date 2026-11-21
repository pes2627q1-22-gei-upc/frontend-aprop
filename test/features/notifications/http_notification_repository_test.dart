import 'dart:async';
import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/activity_json_mapper.dart';
import 'package:aprop/features/notifications/data/http_notification_repository.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/profile/data/http_friendship_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../activities/backend_event_fixture.dart';
import '../activities/fake_activity_repository.dart';
import 'backend_notification_fixture.dart';

http.Response json(Object? data, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(data)),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late FakeActivityRepository activities;
  setUp(() {
    activities = FakeActivityRepository()
      ..findActivity = (id) async =>
          activityFromJson(backendEvent(int.parse(id)));
  });
  HttpNotificationRepository repository(
    Future<http.Response> Function(http.Request) handle, {
    Future<String?> Function()? token,
  }) => HttpNotificationRepository(
    apiClient: ApiClient(
      idToken: token ?? () async => 'test-token',
      client: MockClient(handle),
    ),
    activityRepository: activities,
  );

  test('Acceptance wording in a generic Social notice does not invent a structured acceptance event', () async {
    final client = ApiClient(
      idToken: () async => 'test-token',
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/users/me':
            return json(backendOwnProfile());
          case '/users/me/friend-requests':
            return json([]);
          case '/notifications/user/$backendUserId':
            return json([
              {
                ...backendNotification(8, type: 41, event: null),
                'friend-id': backendOtherUserId,
                'request-date': '2026-10-25T12:34:56.123456',
                'text': "Marc ha acceptat la teva sol·licitud d'amistat",
              },
            ]);
          case '/notificationtypes':
            return json(backendNotificationTypes);
          case '/users/$backendOtherUserId':
            return json({'id': backendOtherUserId, 'name': 'Marc Vidal'});
          default:
            throw StateError('Unexpected endpoint ${request.url}');
        }
      }),
    );
    final repo = HttpNotificationRepository(
      apiClient: client,
      activityRepository: activities,
      friendshipRepository: HttpFriendshipRepository(apiClient: client),
    );
    final notice = (await repo.getNotifications(firebaseAccountId)).single;
    expect(notice.type, NotificationType.socialUpdate);
    expect(notice.category, NotificationCategory.social);
    expect(notice.person!.id, backendOtherUserId);
    expect(notice.requestId, isNull);
    expect(notice.requestStatus, isNull);
  });

  test(
    'Uses the real profile UUID and names from the type catalogue',
    () async {
      final paths = <String>[];
      final repo = repository((request) async {
        paths.add(request.url.path);
        expect(request.headers['Authorization'], 'Bearer test-token');
        if (request.url.path == '/users/me') {
          expect(request.headers.containsKey('X-User-ID'), isFalse);
          return json(backendOwnProfile());
        }
        expect(request.headers.containsKey('X-User-ID'), isFalse);
        if (request.url.path == '/notificationtypes') {
          return json(backendNotificationTypes);
        }
        if (request.url.path == '/users/$backendOtherUserId') {
          return json({'id': backendOtherUserId, 'name': 'Laia Soler'});
        }
        expect(request.url.path, '/notifications/user/$backendUserId');
        return json([
          backendNotification(1),
          backendNotification(2, type: 83),
          {
            ...backendNotification(3, type: 41),
            'friend-id': backendOtherUserId,
          },
        ]);
      });
      final notices = await repo.getNotifications(firebaseAccountId);
      expect(notices.map((n) => n.category), [
        NotificationCategory.reminders,
        NotificationCategory.recommendations,
        NotificationCategory.social,
      ]);
      expect(notices.last.type, NotificationType.socialUpdate);
      expect(notices.last.requestStatus, isNull);
      expect(notices.last.person!.name, 'Laia Soler');
      expect(activities.requestedIds, ['7']);
      expect(paths, [
        '/users/me',
        '/notifications/user/$backendUserId',
        '/notificationtypes',
        '/users/$backendOtherUserId',
      ]);
      expect(() => notices.clear(), throwsUnsupportedError);
    },
  );

  test('A genuine empty inbox needs no type/context lookups', () async {
    final paths = <String>[];
    final repo = repository((request) async {
      paths.add(request.url.path);
      return json(request.url.path == '/users/me' ? backendOwnProfile() : []);
    });
    expect(await repo.getNotifications(firebaseAccountId), isEmpty);
    expect(paths, ['/users/me', '/notifications/user/$backendUserId']);
    expect(activities.requestedIds, isEmpty);
  });

  test('A shared friend reference does not attach actors to reminders or recommendations', () async {
    final repo = repository((request) async {
      if (request.url.path == '/users/me') return json(backendOwnProfile());
      if (request.url.path == '/notificationtypes') {
        return json(backendNotificationTypes);
      }
      if (request.url.path == '/users/$backendOtherUserId') {
        return json({'id': backendOtherUserId, 'name': 'Laia'});
      }
      return json([
        for (final type in [19, 83, 41])
          {
            ...backendNotification(type, type: type),
            'friend-id': backendOtherUserId,
          },
      ]);
    });
    final notices = await repo.getNotifications(firebaseAccountId);
    expect(notices, hasLength(3));
    expect(notices.first.person, isNull);
    expect(notices[1].person, isNull);
    expect(notices.last.person!.name, 'Laia');
  });

  test(
    'Transport and identity failures are not turned into an empty inbox',
    () async {
      for (final failedPath in [
        '/users/me',
        '/notifications/user/$backendUserId',
        '/notificationtypes',
      ]) {
        final repo = repository((request) async {
          if (request.url.path == failedPath) {
            return json({'error': 'offline'}, 503);
          }
          if (request.url.path == '/users/me') return json(backendOwnProfile());
          return json([backendNotification(1)]);
        });
        await expectLater(
          repo.getNotifications(firebaseAccountId),
          throwsA(isA<ApiException>()),
        );
      }
      var calls = 0;
      final noSession = repository((_) async {
        calls++;
        return json([]);
      }, token: () async => null);
      await expectLater(
        noSession.getNotifications(firebaseAccountId),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 0);
    },
  );

  test('Malformed payloads are distinct from an empty inbox', () async {
    for (final body in [
      null,
      {'events': []},
      [null],
      [
        {...backendNotification(1), 'notification-date': null},
      ],
      [
        {...backendNotification(1), 'read': 'false'},
      ],
      [backendNotification(1), backendNotification(1)],
    ]) {
      final repo = repository(
        (request) async =>
            json(request.url.path == '/users/me' ? backendOwnProfile() : body),
      );
      await expectLater(
        repo.getNotifications(firebaseAccountId),
        throwsFormatException,
      );
    }
  });

  test('Wrong account profiles and foreign inbox rows are rejected', () async {
    var inboxCalls = 0;
    final mismatched = repository((request) async {
      if (request.url.path == '/users/me') {
        return json(backendOwnProfile(firebaseId: 'another-account'));
      }
      inboxCalls++;
      return json([]);
    });
    await expectLater(
      mismatched.getNotifications(firebaseAccountId),
      throwsA(isA<ApiException>()),
    );
    expect(inboxCalls, 0);
    final foreign = repository(
      (request) async => json(
        request.url.path == '/users/me'
            ? backendOwnProfile()
            : [
                {...backendNotification(1), 'user-id': backendOtherUserId},
              ],
      ),
    );
    await expectLater(
      foreign.getNotifications(firebaseAccountId),
      throwsFormatException,
    );
  });

  test(
    'Unknown categories remain as unclassified notices without social actions',
    () async {
      final repo = repository((request) async {
        if (request.url.path == '/users/me') return json(backendOwnProfile());
        if (request.url.path == '/notificationtypes') {
          return json([
            ...backendNotificationTypes,
            {'id': 99, 'name': 'A future type'},
          ]);
        }
        return json([
          backendNotification(1, type: 99, event: null),
          backendNotification(2, type: 500, event: null),
        ]);
      });
      final notices = await repo.getNotifications(firebaseAccountId);
      expect(
        notices.map((notice) => notice.type),
        everyElement(NotificationType.other),
      );
      expect(notices.map((notice) => notice.category), everyElement(isNull));
      expect(
        notices.map((notice) => notice.requestStatus),
        everyElement(isNull),
      );
    },
  );

  test(
    'Missing and temporarily unavailable activities preserve received notices',
    () async {
      activities.findActivity = (id) async {
        if (id == '7') return null;
        throw ApiException.network();
      };
      final repo = repository((request) async {
        if (request.url.path == '/users/me') return json(backendOwnProfile());
        if (request.url.path == '/notificationtypes') {
          return json(backendNotificationTypes);
        }
        return json([backendNotification(1), backendNotification(2, event: 8)]);
      });
      final notices = await repo.getNotifications(firebaseAccountId);
      expect(notices, hasLength(2));
      expect(notices.first.activityId, '7');
      expect(notices.first.activityUnavailable, isTrue);
      expect(notices.first.canOpenActivity, isFalse);
      expect(notices.last.activityId, '8');
      expect(notices.last.activityUnavailable, isFalse);
      expect(notices.last.canOpenActivity, isTrue);
    },
  );

  test(
    'One lookup per unique actor; missing names do not drop social notices',
    () async {
      var actorCalls = 0;
      final repo = repository((request) async {
        if (request.url.path == '/users/me') return json(backendOwnProfile());
        if (request.url.path == '/notificationtypes') {
          return json(backendNotificationTypes);
        }
        if (request.url.path == '/users/$backendOtherUserId') {
          actorCalls++;
          return json({'error': 'not found'}, 404);
        }
        return json([
          for (var id = 1; id <= 3; id++)
            {
              ...backendNotification(id, type: 41, event: null),
              'friend-id': backendOtherUserId,
            },
        ]);
      });
      final notices = await repo.getNotifications(firebaseAccountId);
      expect(notices, hasLength(3));
      expect(notices.first.person!.name, 'Una persona');
      expect(actorCalls, 1);
    },
  );

  test('Reading is persisted only after success, and refresh reads the server state', () async {
    var read = false;
    var fail = true;
    var writes = 0;
    final repo = repository((request) async {
      if (request.url.path == '/users/me') return json(backendOwnProfile());
      if (request.url.path == '/notificationtypes') {
        return json(backendNotificationTypes);
      }
      if (request.method == 'POST') {
        writes++;
        expect(request.url.path, '/notifications/1/read');
        if (fail) return json({'error': 'offline'}, 503);
        read = true;
        return json({'message': 'notification 1 read'});
      }
      final notice = backendNotification(1, read: read);
      return json(request.url.path == '/notifications/1' ? notice : [notice]);
    });
    expect(
      (await repo.getNotifications(firebaseAccountId)).single.isRead,
      isFalse,
    );
    await expectLater(
      repo.markAsRead(userId: firebaseAccountId, notificationId: '1'),
      throwsA(isA<ApiException>()),
    );
    expect(read, isFalse);
    fail = false;
    await repo.markAsRead(userId: firebaseAccountId, notificationId: '1');
    await repo.markAsRead(userId: firebaseAccountId, notificationId: '1');
    expect(writes, 2);
    expect(
      (await repo.getNotifications(firebaseAccountId)).single.isRead,
      isTrue,
    );
  });

  test(
    'Reading a foreign or different notification never sends a write',
    () async {
      for (final row in [
        {...backendNotification(1), 'user-id': backendOtherUserId},
        backendNotification(2),
      ]) {
        var writes = 0;
        final repo = repository((request) async {
          if (request.url.path == '/users/me') return json(backendOwnProfile());
          if (request.method == 'POST') writes++;
          return json(row);
        });
        await expectLater(
          repo.markAsRead(userId: firebaseAccountId, notificationId: '1'),
          throwsFormatException,
        );
        expect(writes, 0);
      }
    },
  );

  test(
    'One operation keeps its token while the next account resolves afresh',
    () async {
      var token = 'first-token';
      var currentAccount = firebaseAccountId;
      final seenTokens = <String?>[];
      final repo = repository((request) async {
        if (request.url.path == '/users/me') {
          final profile = currentAccount == firebaseAccountId
              ? backendOwnProfile()
              : backendOwnProfile(
                  id: backendOtherUserId,
                  firebaseId: currentAccount,
                );
          token = 'second-token';
          return json(profile);
        }
        seenTokens.add(request.headers['Authorization']);
        return json([]);
      }, token: () async => token);
      await repo.getNotifications(firebaseAccountId);
      currentAccount = 'second-account';
      await repo.getNotifications(currentAccount);
      expect(seenTokens, ['Bearer first-token', 'Bearer second-token']);
    },
  );

  test('Context lookup concurrency is bounded', () async {
    var active = 0;
    var maximum = 0;
    final gates = <Completer<void>>[];
    activities.findActivity = (id) async {
      active++;
      if (active > maximum) maximum = active;
      final gate = Completer<void>();
      gates.add(gate);
      await gate.future;
      active--;
      return activityFromJson(backendEvent(int.parse(id)));
    };
    final repo = repository((request) async {
      if (request.url.path == '/users/me') return json(backendOwnProfile());
      if (request.url.path == '/notificationtypes') {
        return json(backendNotificationTypes);
      }
      return json([
        for (var id = 1; id <= 6; id++) backendNotification(id, event: id),
      ]);
    });
    final loading = repo.getNotifications(firebaseAccountId);
    await Future<void>.delayed(Duration.zero);
    expect(gates, hasLength(4));
    for (final gate in gates.toList()) {
      gate.complete();
    }
    await Future<void>.delayed(Duration.zero);
    expect(gates, hasLength(6));
    for (final gate in gates.skip(4)) {
      gate.complete();
    }
    await loading;
    expect(maximum, 4);
  });

  test('HTTP friendship responses never simulate confirmation', () async {
    var calls = 0;
    final repo = repository((_) async {
      calls++;
      return json({});
    });
    await expectLater(
      repo.respondToFriendRequest(
        userId: firebaseAccountId,
        requestId: 'req-1',
        accept: true,
      ),
      throwsUnsupportedError,
    );
    expect(calls, 0);
  });
}
