import 'dart:async';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/profile/data/http_friendship_repository.dart';
import 'package:aprop/features/profile/models/friendship_removal.dart';
import 'package:aprop/features/profile/models/received_friend_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'backend_friend_request_fixture.dart';
import 'backend_profile_fixture.dart';
import 'friendship_test_support.dart';

void main() {
  test('Removal uses the real endpoint, pinned bearer and only publishes after confirmation', () async {
    final response = Completer<http.Response>();
    var posts = 0;
    var token = 'token-a';
    final client = ApiClient(
      idToken: () async => token,
      client: MockClient((r) async {
        expect(r.headers['Authorization'], 'Bearer token-a');
        expect(r.headers.containsKey('X-User-ID'), isFalse);
        if (r.url.path == '/users/me') {
          token = 'token-b';
          return jsonResponse(backendProfile());
        }
        expect(r.url.path, '/users/$otherProfileServerId/unfriend');
        expect(r.method, 'POST');
        expect(r.body, isEmpty);
        posts++;
        return response.future;
      }),
    );
    addTearDown(client.close);
    final repo = HttpFriendshipRepository(apiClient: client);
    addTearDown(repo.dispose);
    final changes = <FriendshipRemoval>[];
    final sub = repo.watchRemovals('user-a').listen(changes.add);
    addTearDown(sub.cancel);
    final first = repo.removeFriend(
      userId: 'user-a',
      friendId: otherProfileServerId,
    );
    final duplicate = repo.removeFriend(
      userId: 'user-a',
      friendId: otherProfileServerId,
    );
    await Future<void>.delayed(Duration.zero);
    expect(posts, 1);
    expect(changes, isEmpty);
    expect(repo.confirmedFriendship('user-a', otherProfileServerId), isNull);
    response.complete(
      jsonResponse({'message': 'friendship deleted successfully'}),
    );
    await Future.wait([first, duplicate]);
    expect(changes.single.friendId, otherProfileServerId);
    expect(repo.confirmedFriendship('user-a', otherProfileServerId), isFalse);
    expect(
      repo.confirmedFriendship('another-account', otherProfileServerId),
      isNull,
    );
    expect(() => repo.removedFriends('user-a').clear(), throwsUnsupportedError);
  });

  for (final status in [400, 401, 403, 404, 500]) {
    test('HTTP $status does not confirm removal and allows retry', () async {
      var fail = true;
      final client = ApiClient(
        idToken: () async => 'token',
        client: MockClient((r) async {
          if (r.url.path == '/users/me') return jsonResponse(backendProfile());
          return fail
              ? jsonResponse({'error': 'cannot remove'}, status)
              : jsonResponse({'message': 'removed'});
        }),
      );
      addTearDown(client.close);
      final repo = HttpFriendshipRepository(apiClient: client);
      addTearDown(repo.dispose);
      await expectLater(
        repo.removeFriend(userId: 'user-a', friendId: otherProfileServerId),
        throwsA(isA<ApiException>()),
      );
      expect(repo.removedFriends('user-a'), isEmpty);
      fail = false;
      await repo.removeFriend(userId: 'user-a', friendId: otherProfileServerId);
      expect(repo.confirmedFriendship('user-a', otherProfileServerId), isFalse);
    });
  }

  test(
    'Changed accounts, invalid targets and self-removal never issue the POST',
    () async {
      var posts = 0;
      final client = ApiClient(
        idToken: () async => 'token',
        client: MockClient((r) async {
          if (r.method == 'POST') posts++;
          return jsonResponse(backendProfile(account: 'other-account'));
        }),
      );
      addTearDown(client.close);
      final repo = HttpFriendshipRepository(apiClient: client);
      addTearDown(repo.dispose);
      await expectLater(
        repo.removeFriend(userId: 'user-a', friendId: otherProfileServerId),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        repo.removeFriend(userId: 'other-account', friendId: profileServerId),
        throwsArgumentError,
      );
      await expectLater(
        repo.removeFriend(userId: 'other-account', friendId: '../bad'),
        throwsFormatException,
      );
      expect(posts, 0);
    },
  );

  test('Acceptance and removal serialize for the same relationship; history cannot restore friendship', () async {
    final request = ReceivedFriendRequest(
      senderId: 'peer',
      receiverId: 'viewer',
      sentAt: DateTime.utc(2026, 11, 21),
    );
    final repo = ControlledFriendshipRepository(request);
    addTearDown(repo.dispose);
    final accepted = Completer<FriendRequestResolution>();
    repo.onRespond = (_) => accepted.future;
    await repo.getReceivedRequests('viewer');
    final first = repo.respond(
      userId: 'viewer',
      requestId: request.id,
      accept: true,
    );
    final second = repo.removeFriend(userId: 'viewer', friendId: 'peer');
    await Future<void>.delayed(Duration.zero);
    expect(repo.removals, isEmpty);
    accepted.complete(
      FriendRequestResolution(
        request: request,
        status: FriendRequestStatus.accepted,
      ),
    );
    await Future.wait([first, second]);
    expect(repo.removals, [('viewer', 'peer')]);
    expect(
      repo.resolutions('viewer').single.status,
      FriendRequestStatus.accepted,
    );
    expect(repo.confirmedFriendship('viewer', 'peer'), isFalse);
    expect(await repo.getReceivedRequests('viewer'), isEmpty);
  });

  test('Disposing during a removal does not publish a late change', () async {
    final repo = ControlledFriendshipRepository(
      ReceivedFriendRequest(
        senderId: 'peer',
        receiverId: 'viewer',
        sentAt: DateTime.utc(2026),
      ),
    );
    final pending = Completer<void>();
    repo.onRemove = () => pending.future;
    final changes = <FriendshipRemoval>[];
    final sub = repo.watchRemovals('viewer').listen(changes.add);
    final removal = repo.removeFriend(userId: 'viewer', friendId: 'peer');
    await repo.dispose();
    pending.complete();
    await removal;
    expect(changes, isEmpty);
    expect(repo.removedFriends('viewer'), isEmpty);
    await sub.cancel();
  });
}
