import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/profile/data/http_public_profile_repository.dart';
import 'package:aprop/features/profile/repositories/public_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../activities/backend_event_fixture.dart';
import 'backend_profile_fixture.dart';

http.Response _json(Object? body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

/// `GET /users/{id}` as another person sees it: no e-mail or Firebase UID.
Map<String, Object?> _otherProfile({
  bool? isFriend = false,
  bool plansVisible = false,
}) {
  final json = {...backendProfile(), 'id': otherProfileServerId}
    ..remove('firebase-uid')
    ..['plans-visible'] = plansVisible;
  if (isFriend != null) json['is-friend'] = isFriend;
  return json;
}

void main() {
  HttpPublicProfileRepository repository(
    Future<http.Response> Function(http.Request) handle,
  ) => HttpPublicProfileRepository(
    apiClient: ApiClient(
      idToken: () async => 'profile-token',
      client: MockClient(handle),
    ),
    now: () => DateTime.utc(2026, 11, 20),
  );

  test(
    'Loads another person with the session token and their privacy',
    () async {
      final repo = repository((request) async {
        expect(request.url.path, '/users/$otherProfileServerId');
        expect(request.headers['Authorization'], 'Bearer profile-token');
        return _json(_otherProfile(isFriend: true, plansVisible: true));
      });

      final person = await repo.getPublicProfile(otherProfileServerId);

      expect(person.profile.userId, otherProfileServerId);
      expect(person.profile.displayName, 'Maria Soler');
      expect(person.profile.username, 'maria');
      expect(person.profile.friendCount, 3);
      expect(person.profile.organizerRating, 4.5);
      expect(person.isFriend, isTrue);
      expect(person.plansVisible, isTrue);
    },
  );

  test('Missing privacy fields keep the plans private', () async {
    final repo = repository((request) async {
      return _json(_otherProfile(isFriend: null)..remove('plans-visible'));
    });

    final person = await repo.getPublicProfile(otherProfileServerId);

    expect(person.isFriend, isNull);
    expect(person.plansVisible, isFalse);
  });

  test('A 404 means the person does not exist', () async {
    final repo = repository((request) async => _json({'error': 'nope'}, 404));

    expect(
      repo.getPublicProfile(otherProfileServerId),
      throwsA(isA<PublicProfileNotFound>()),
    );
  });

  test('Rejects a profile that belongs to someone else', () async {
    final repo = repository((request) async => _json(backendProfile()));

    expect(repo.getPublicProfile(otherProfileServerId), throwsFormatException);
  });

  test(
    'Created activities come from the person and are community ones',
    () async {
      final repo = repository((request) async {
        expect(request.url.path, '/users/$otherProfileServerId/created-events');
        return _json([
          {
            ...backendEvent(7),
            'is-official': false,
            'creator': otherProfileServerId,
          },
        ]);
      });

      final created = await repo.getCreatedActivities(otherProfileServerId);

      expect(created.single.id, '7');
      expect(() => created.clear(), throwsUnsupportedError);
    },
  );

  test('Rejects created activities of another creator', () async {
    final repo = repository(
      (request) async => _json([
        {...backendEvent(7), 'is-official': false, 'creator': profileServerId},
      ]),
    );

    expect(
      repo.getCreatedActivities(otherProfileServerId),
      throwsFormatException,
    );
  });

  test('Past plans keep only started activities, newest first', () async {
    final repo = repository((request) async {
      expect(request.url.path, '/users/$otherProfileServerId/events');
      return _json([
        {...backendEvent(1), 'start-date': '2026-10-01T18:00:00Z'},
        {...backendEvent(2), 'start-date': '2026-12-01T18:00:00Z'},
        {...backendEvent(3), 'start-date': '2026-11-10T18:00:00Z'},
      ]);
    });

    final plans = await repo.getPastPlans(otherProfileServerId);

    expect(plans.map((a) => a.id), ['3', '1']);
  });

  test('A malformed list is an error, not an empty list', () async {
    final repo = repository((request) async => _json({'events': []}));

    expect(repo.getPastPlans(otherProfileServerId), throwsFormatException);
    expect(
      repo.getCreatedActivities(otherProfileServerId),
      throwsFormatException,
    );
  });

  group('Friend requests (#160)', () {
    test('Posts the request with the session token', () async {
      final repo = repository((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          '/users/$otherProfileServerId/friend-requests',
        );
        expect(request.headers['Authorization'], 'Bearer profile-token');
        return _json({
          'sender-id': profileServerId,
          'receiver-id': otherProfileServerId,
          'state': 'Pendent',
        });
      });

      expect(
        await repo.sendFriendRequest(otherProfileServerId),
        FriendRequestResult.sent,
      );
    });

    test('The server text tells the 400 refusals apart', () async {
      for (final (text, expected) in [
        (
          'pending friend request exists between these users',
          FriendRequestResult.alreadyPending,
        ),
        (
          'requester is already friends with target user',
          FriendRequestResult.alreadyFriends,
        ),
        (
          'requester has blocked or been blocked by target user',
          FriendRequestResult.blocked,
        ),
      ]) {
        final repo = repository((request) async => _json({'error': text}, 400));
        expect(
          await repo.sendFriendRequest(otherProfileServerId),
          expected,
          reason: text,
        );
      }
    });

    test('Other failures are errors, not a sent request', () async {
      expect(
        repository((request) async => _json({'error': 'something else'}, 400))
            .sendFriendRequest(otherProfileServerId),
        throwsA(isA<ApiException>()),
      );
      expect(
        repository((request) async => _json({'error': 'boom'}, 500))
            .sendFriendRequest(otherProfileServerId),
        throwsA(isA<ApiException>()),
      );
      expect(
        repository((request) async => _json({'error': 'user not found'}, 404))
            .sendFriendRequest(otherProfileServerId),
        throwsA(isA<PublicProfileNotFound>()),
      );
    });
  });
}
