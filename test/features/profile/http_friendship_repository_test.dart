import 'dart:async';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/profile/data/http_friendship_repository.dart';
import 'package:aprop/features/profile/models/received_friend_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'backend_profile_fixture.dart';
import 'backend_friend_request_fixture.dart';

void main() {
  HttpFriendshipRepository repo(
    Future<http.Response> Function(http.Request) handle, {
    String? token = 'friend-token',
  }) => HttpFriendshipRepository(
    apiClient: ApiClient(
      client: MockClient(handle),
      idToken: () async => token,
    ),
  );

  test('Accept and deny use the exact sender/date, authorize the receiver, and publish once', () async {
    for (final accept in [true, false]) {
      final paths = <String>[];
      final repository = repo((r) async {
        expect(r.headers['Authorization'], 'Bearer friend-token');
        expect(r.headers.containsKey('X-User-ID'), isFalse);
        paths.add(r.url.path);
        if (r.url.path == '/users/me') return jsonResponse(backendProfile());
        if (r.method == 'GET') return jsonResponse([requestJson()]);
        expect(r.url.pathSegments, [
          'users',
          otherProfileServerId,
          'friend-requests',
          sent,
          accept ? 'accept' : 'deny',
        ]);
        return jsonResponse(
          requestJson(state: accept ? 'Accepted' : 'Rejected'),
        );
      });
      final events = <FriendRequestResolution>[];
      final sub = repository.watchChanges('user-a').listen(events.add);
      final pending = await repository.getReceivedRequests('user-a');
      expect(pending.single.sentAt.microsecond, 456);
      final first = await repository.respond(
        userId: 'user-a',
        requestId: pending.single.id,
        accept: accept,
      );
      final again = await repository.respond(
        userId: 'user-a',
        requestId: pending.single.id,
        accept: !accept,
      );
      expect(again, same(first));
      expect(events, hasLength(1));
      expect(
        paths.where((p) => p.endsWith('/accept') || p.endsWith('/deny')),
        hasLength(1),
      );
      expect(
        await repository.getReceivedRequests('user-a'),
        isEmpty,
      ); // even a stale server read cannot undo confirmation
      await sub.cancel();
      await repository.dispose();
    }
  });

  test('Concurrent buttons share one pending mutation and expose no optimistic success', () async {
    final response = Completer<http.Response>();
    var posts = 0;
    final repository = repo((r) async {
      if (r.url.path == '/users/me') return jsonResponse(backendProfile());
      if (r.method == 'GET') return jsonResponse([requestJson()]);
      posts++;
      return response.future;
    });
    final request = (await repository.getReceivedRequests('user-a')).single;
    final a = repository.respond(
      userId: 'user-a',
      requestId: request.id,
      accept: true,
    );
    final b = repository.respond(
      userId: 'user-a',
      requestId: request.id,
      accept: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(posts, 1);
    expect(repository.resolutions('user-a'), isEmpty);
    response.complete(jsonResponse(requestJson(state: 'Accepted')));
    expect(await a, same(await b));
    await repository.dispose();
  });

  test('An old pending read cannot reintroduce an accepted request', () async {
    final response = Completer<http.Response>();
    var lists = 0;
    final repository = repo((r) async {
      if (r.url.path == '/users/me') return jsonResponse(backendProfile());
      if (r.method == 'POST') {
        return jsonResponse(requestJson(state: 'Accepted'));
      }
      lists++;
      return lists == 1 ? jsonResponse([requestJson()]) : response.future;
    });
    final request = (await repository.getReceivedRequests('user-a')).single;
    final stale = repository.getReceivedRequests('user-a');
    await repository.respond(
      userId: 'user-a',
      requestId: request.id,
      accept: true,
    );
    response.complete(jsonResponse([requestJson()]));
    expect(await stale, isEmpty);
    await repository.dispose();
  });

  for (final change in <Map<String, Object?>>[
    {'state': 'Pending'},
    {'state': 'Rejected'},
    {'sender-id': profileServerId},
    {'receiver-id': otherProfileServerId},
    {'date-sent': '2026-11-20T12:34:56.123455Z'},
  ]) {
    test(
      'A forged/mismatching response never publishes success: $change',
      () async {
        final repository = repo((r) async {
          if (r.url.path == '/users/me') return jsonResponse(backendProfile());
          if (r.method == 'GET') return jsonResponse([requestJson()]);
          return jsonResponse({...requestJson(state: 'Accepted'), ...change});
        });
        final request = (await repository.getReceivedRequests('user-a')).single;
        await expectLater(
          repository.respond(
            userId: 'user-a',
            requestId: request.id,
            accept: true,
          ),
          throwsFormatException,
        );
        expect(repository.resolutions('user-a'), isEmpty);
        await repository.dispose();
      },
    );
  }

  test(
    'Network failure permits retry and changed account never writes',
    () async {
      var fails = true;
      var wrongAccount = false;
      var posts = 0;
      final repository = repo((r) async {
        if (r.url.path == '/users/me') {
          return jsonResponse(
            backendProfile(
              account: wrongAccount ? 'another-account' : 'user-a',
            ),
          );
        }
        if (r.method == 'GET') return jsonResponse([requestJson()]);
        posts++;
        return fails
            ? jsonResponse({'error': 'offline'}, 503)
            : jsonResponse(requestJson(state: 'Accepted'));
      });
      final request = (await repository.getReceivedRequests('user-a')).single;
      await expectLater(
        repository.respond(
          userId: 'user-a',
          requestId: request.id,
          accept: true,
        ),
        throwsA(isA<ApiException>()),
      );
      expect(repository.resolutions('user-a'), isEmpty);
      wrongAccount = true;
      await expectLater(
        repository.respond(
          userId: 'user-a',
          requestId: request.id,
          accept: true,
        ),
        throwsA(isA<ApiException>()),
      );
      expect(posts, 1);
      wrongAccount = false;
      fails = false;
      expect(
        (await repository.respond(
          userId: 'user-a',
          requestId: request.id,
          accept: true,
        )).status,
        FriendRequestStatus.accepted,
      );
      expect(repository.resolutions('another-account'), isEmpty);
      await repository.dispose();
    },
  );

  test(
    'No bearer or wrong recipient/self request never enables actions',
    () async {
      final noAuth = repo(
        (_) async => throw StateError('must not call'),
        token: null,
      );
      await expectLater(
        noAuth.getReceivedRequests('user-a'),
        throwsA(isA<ApiException>()),
      );
      await noAuth.dispose();
      for (final change in [
        {'receiver-id': otherProfileServerId},
        {'sender-id': profileServerId},
      ]) {
        final repository = repo(
          (r) async => jsonResponse(
            r.url.path == '/users/me'
                ? backendProfile()
                : [
                    {...requestJson(), ...change},
                  ],
          ),
        );
        await expectLater(
          repository.getReceivedRequests('user-a'),
          throwsFormatException,
        );
        await repository.dispose();
      }
    },
  );
}
