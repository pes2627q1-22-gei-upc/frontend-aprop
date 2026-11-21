import 'dart:async';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/profile/data/demo_friendship_repository.dart';
import 'package:aprop/features/profile/data/http_friendship_repository.dart';
import 'package:aprop/features/profile/models/blocked_user.dart';
import 'package:aprop/features/profile/models/received_friend_request.dart';
import 'package:aprop/features/profile/models/user_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'backend_friend_request_fixture.dart';
import 'backend_profile_fixture.dart';
import 'friendship_test_support.dart';

const blockingTarget = UserSummary(
  id: otherProfileServerId,
  username: 'marc',
  displayName: 'Marc Vidal',
);
Map<String, Object?> blockedJson() => {
  'id': otherProfileServerId,
  'username': 'marc',
  'name': 'Marc Vidal',
  'profile-picture': 'https://example.test/avatar.png',
  'date-blocked': '2026-11-21T12:34:56.123456Z',
};

void main() {
  test('Authoritative external block-list changes invalidate older incoming-request reads', () async {
    final repo = ControlledFriendshipRepository(
      DemoFriendshipRepository.marcRequest('viewer'),
    );
    addTearDown(repo.dispose);
    final pending = Completer<List<ReceivedFriendRequest>>();
    repo.onFetch = () => pending.future;
    final reading = repo.getReceivedRequests('viewer');
    repo.blockedUsers[repo.request.senderId] = BlockedUser(
      user: UserSummary(
        id: repo.request.senderId,
        username: 'marc',
        displayName: 'Marc',
      ),
      blockedAt: DateTime.utc(2026),
    );
    await repo.getBlockedUsers('viewer');
    repo.blockedUsers.clear();
    await repo.getBlockedUsers('viewer');
    repo.onFetch = () async => [];
    pending.complete([repo.request]);
    expect(await reading, isEmpty);
  });
  HttpFriendshipRepository make(
    Future<http.Response> Function(http.Request) handle,
  ) {
    final client = ApiClient(
      idToken: () async => 'token',
      client: MockClient(handle),
    );
    addTearDown(client.close);
    final repo = HttpFriendshipRepository(apiClient: client);
    addTearDown(repo.dispose);
    return repo;
  }

  test('GET/POST/DELETE use authenticated endpoints; blocking removes friendship and unblocking does not restore it', () async {
    var blocked = false;
    final writes = <String>[];
    final repo = make((r) async {
      expect(r.headers['Authorization'], 'Bearer token');
      expect(r.headers.containsKey('X-User-ID'), isFalse);
      if (r.url.path == '/users/me') return jsonResponse(backendProfile());
      if (r.url.path == '/users/me/blocked') {
        return jsonResponse(blocked ? [blockedJson()] : []);
      }
      expect(r.url.path, '/users/$otherProfileServerId/block');
      expect(r.body, isEmpty);
      writes.add(r.method);
      if (r.method == 'POST') {
        blocked = true;
        return jsonResponse(blockedJson(), 201);
      }
      expect(r.method, 'DELETE');
      blocked = false;
      return http.Response('', 204);
    });
    expect(repo.cachedBlockedUsers('user-a'), isNull);
    expect(await repo.getBlockedUsers('user-a'), isEmpty);
    final result = await repo.blockUser(
      userId: 'user-a',
      target: blockingTarget,
    );
    expect(result.user.displayName, 'Marc Vidal');
    expect(result.blockedAt.microsecond, 456);
    expect(repo.isBlocked('user-a', otherProfileServerId), isTrue);
    expect(repo.confirmedFriendship('user-a', otherProfileServerId), isFalse);
    expect(
      repo.cachedBlockedUsers('user-a')!.single.user.id,
      otherProfileServerId,
    );
    await repo.unblockUser(userId: 'user-a', targetId: otherProfileServerId);
    expect(repo.isBlocked('user-a', otherProfileServerId), isFalse);
    expect(repo.cachedBlockedUsers('user-a'), isEmpty);
    expect(repo.confirmedFriendship('user-a', otherProfileServerId), isFalse);
    expect(writes, ['POST', 'DELETE']);
  });

  for (final status in [400, 401, 403, 500]) {
    test(
      'HTTP $status cannot create a local block and a retry can succeed',
      () async {
        var fail = true;
        final repo = make(
          (r) async => r.url.path == '/users/me'
              ? jsonResponse(backendProfile())
              : fail
              ? jsonResponse({'error': 'blocked failed'}, status)
              : jsonResponse(blockedJson(), 201),
        );
        await expectLater(
          repo.blockUser(userId: 'user-a', target: blockingTarget),
          throwsA(isA<ApiException>()),
        );
        expect(repo.isBlocked('user-a', otherProfileServerId), isNull);
        fail = false;
        await repo.blockUser(userId: 'user-a', target: blockingTarget);
        expect(repo.isBlocked('user-a', otherProfileServerId), isTrue);
      },
    );
  }

  test('409 is confirmed by the owned list; 404 unblocking is confirmed only when absent', () async {
    var present = true;
    final repo = make((r) async {
      if (r.url.path == '/users/me') return jsonResponse(backendProfile());
      if (r.url.path == '/users/me/blocked') {
        return jsonResponse(present ? [blockedJson()] : []);
      }
      return jsonResponse({
        'error': 'conflict',
      }, r.method == 'POST' ? 409 : 404);
    });
    await repo.blockUser(userId: 'user-a', target: blockingTarget);
    await expectLater(
      repo.unblockUser(userId: 'user-a', targetId: otherProfileServerId),
      throwsA(isA<ApiException>()),
    );
    expect(repo.isBlocked('user-a', otherProfileServerId), isTrue);
    present = false;
    await repo.unblockUser(userId: 'user-a', targetId: otherProfileServerId);
    expect(repo.isBlocked('user-a', otherProfileServerId), isFalse);
  });

  for (final payload in <Object?>[
    {},
    [blockedJson(), blockedJson()],
    [
      {...blockedJson(), 'id': profileServerId},
    ],
    [
      {...blockedJson(), 'date-blocked': 'bad'},
    ],
    [
      {...blockedJson(), 'username': ''},
    ],
  ]) {
    test(
      'Malformed blocked payload ${payload.toString()} is an error, not an empty list',
      () async {
        final repo = make(
          (r) async => jsonResponse(
            r.url.path == '/users/me' ? backendProfile() : payload,
          ),
        );
        await expectLater(
          repo.getBlockedUsers('user-a'),
          throwsFormatException,
        );
        expect(repo.cachedBlockedUsers('user-a'), isNull);
      },
    );
  }

  test('A different session and self-block do not issue mutations', () async {
    var posts = 0;
    final repo = make((r) async {
      if (r.method == 'POST') posts++;
      return jsonResponse(backendProfile(account: 'another-account'));
    });
    await expectLater(
      repo.blockUser(userId: 'user-a', target: blockingTarget),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      repo.blockUser(
        userId: 'another-account',
        target: const UserSummary(
          id: profileServerId,
          username: 'self',
          displayName: 'Self',
        ),
      ),
      throwsArgumentError,
    );
    expect(posts, 0);
  });

  test(
    'Block mutations pin the bearer even when the active token changes',
    () async {
      var token = 'first';
      final client = ApiClient(
        idToken: () async => token,
        client: MockClient((r) async {
          expect(r.headers['Authorization'], 'Bearer first');
          if (r.url.path == '/users/me') {
            token = 'second';
            return jsonResponse(backendProfile());
          }
          return jsonResponse(blockedJson(), 201);
        }),
      );
      addTearDown(client.close);
      final repo = HttpFriendshipRepository(apiClient: client);
      addTearDown(repo.dispose);
      await repo.blockUser(userId: 'user-a', target: blockingTarget);
    },
  );

  test('Stale list reads cannot undo confirmed block or unblock', () async {
    final repo = ControlledFriendshipRepository(
      DemoFriendshipRepository.marcRequest('viewer'),
    );
    addTearDown(repo.dispose);
    final pending = Completer<List<BlockedUser>>();
    repo.onFetchBlocked = () => pending.future;
    final reading = repo.getBlockedUsers('viewer');
    await repo.blockUser(userId: 'viewer', target: blockingTarget);
    pending.complete([]);
    expect((await reading).single.user.id, otherProfileServerId);
    final old = repo.cachedBlockedUsers('viewer')!;
    final pendingAgain = Completer<List<BlockedUser>>();
    repo.onFetchBlocked = () => pendingAgain.future;
    final reloading = repo.getBlockedUsers('viewer');
    await repo.unblockUser(userId: 'viewer', targetId: otherProfileServerId);
    pendingAgain.complete(old);
    expect(await reloading, isEmpty);
  });

  test('Duplicate blocks share a write; the opposite operation waits and accounts stay isolated', () async {
    final repo = ControlledFriendshipRepository(
      DemoFriendshipRepository.marcRequest('viewer'),
    );
    addTearDown(repo.dispose);
    final pending = Completer<BlockedUser>();
    repo.onBlock = (_) => pending.future;
    final first = repo.blockUser(userId: 'viewer', target: blockingTarget);
    final same = repo.blockUser(userId: 'viewer', target: blockingTarget);
    final undo = repo.unblockUser(
      userId: 'viewer',
      targetId: otherProfileServerId,
    );
    expect(repo.blocks, hasLength(1));
    expect(repo.unblocks, isEmpty);
    expect(repo.isBlocked('viewer', otherProfileServerId), isNull);
    pending.complete(
      BlockedUser(user: blockingTarget, blockedAt: DateTime.utc(2026)),
    );
    await Future.wait([first, same, undo]);
    expect(repo.unblocks, [otherProfileServerId]);
    expect(repo.isBlocked('viewer', otherProfileServerId), isFalse);
    expect(repo.isBlocked('another-account', otherProfileServerId), isNull);
  });

  test('A received-request read started before block/unblock is refreshed, not revived', () async {
    final repo = ControlledFriendshipRepository(
      DemoFriendshipRepository.marcRequest('viewer'),
    );
    addTearDown(repo.dispose);
    final pending = Completer<List<ReceivedFriendRequest>>();
    repo.onFetch = () => pending.future;
    final reading = repo.getReceivedRequests('viewer');
    final target = UserSummary(
      id: repo.request.senderId,
      username: 'marc',
      displayName: 'Marc',
    );
    await repo.blockUser(userId: 'viewer', target: target);
    await repo.unblockUser(userId: 'viewer', targetId: target.id);
    repo.onFetch = () async => [];
    pending.complete([repo.request]);
    expect(await reading, isEmpty);
  });
}
