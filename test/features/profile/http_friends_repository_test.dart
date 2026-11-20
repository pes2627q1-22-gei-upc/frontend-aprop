import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/profile/data/http_friends_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'backend_profile_fixture.dart';

http.Response _json(Object? body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

const _thirdId = '33333333-3333-4333-8333-333333333333';

Map<String, Object?> _person(String id, String username, String name) => {
  ...backendProfile(),
  'id': id,
  'username': username,
  'name': name,
};

void main() {
  HttpFriendsRepository repository(
    Future<http.Response> Function(http.Request) handle,
  ) => HttpFriendsRepository(
    apiClient: ApiClient(
      idToken: () async => 'profile-token',
      client: MockClient(handle),
    ),
  );

  test('Own friends: IDs from /users/me/friends, then each profile', () async {
    final paths = <String>[];
    final repo = repository((request) async {
      paths.add(request.url.path);
      expect(request.headers['Authorization'], 'Bearer profile-token');
      return switch (request.url.path) {
        '/users/me/friends' => _json([otherProfileServerId, _thirdId]),
        '/users/$otherProfileServerId' => _json(
          _person(otherProfileServerId, 'marc', 'Marc Vidal'),
        ),
        _ => _json(_person(_thirdId, 'julia', '')),
      };
    });

    final friends = await repo.getFriends();

    expect(paths.first, '/users/me/friends');
    // Server order; an empty name falls back to the username.
    expect(friends.map((f) => f.displayName), ['Marc Vidal', 'julia']);
    expect(friends.first.username, 'marc');
    expect(friends.first.avatarUrl, 'https://images.example.test/avatar.png');
    expect(() => friends.clear(), throwsUnsupportedError);
  });

  test('Another person’s friends use their ID', () async {
    final repo = repository((request) async {
      if (request.url.path.endsWith('/friends')) {
        expect(request.url.path, '/users/$profileServerId/friends');
        return _json(<String>[]);
      }
      fail('No profile should be requested');
    });

    expect(await repo.getFriends(userId: profileServerId), isEmpty);
  });

  test('A deleted friend is left out; other failures are errors', () async {
    final deleted = repository((request) async {
      if (request.url.path.endsWith('/friends')) {
        return _json([otherProfileServerId, _thirdId]);
      }
      if (request.url.path == '/users/$_thirdId') {
        return _json({'error': 'user not found'}, 404);
      }
      return _json(_person(otherProfileServerId, 'marc', 'Marc Vidal'));
    });
    expect((await deleted.getFriends()).map((f) => f.id), [
      otherProfileServerId,
    ]);

    final failing = repository((request) async {
      if (request.url.path.endsWith('/friends')) {
        return _json([otherProfileServerId]);
      }
      return _json({'error': 'boom'}, 500);
    });
    expect(failing.getFriends(), throwsA(isA<ApiException>()));
  });

  test('Malformed answers are errors, not an empty list', () async {
    expect(
      repository((request) async => _json({'friends': []})).getFriends(),
      throwsFormatException,
    );
    expect(
      repository((request) async {
        if (request.url.path.endsWith('/friends')) {
          return _json([otherProfileServerId]);
        }
        // The profile of someone else.
        return _json(_person(_thirdId, 'julia', 'Júlia'));
      }).getFriends(),
      throwsFormatException,
    );
  });
}
