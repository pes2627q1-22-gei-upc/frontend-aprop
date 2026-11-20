import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/profile/data/demo_public_profile_repository.dart';
import 'package:aprop/features/profile/data/demo_user_search_repository.dart';
import 'package:aprop/features/profile/data/http_user_search_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object?> _person(int id) => {
  'id': '22222222-2222-2222-2222-${id.toString().padLeft(12, '0')}',
  'username': 'julia$id',
  'name': 'Júlia Riera',
  'profile-picture': '',
};

Map<String, Object?> _page({String query = 'Júlia', int page = 0}) => {
  'query': query,
  'page-num': page,
  'page-size': 20,
  'total': 1,
  'users': [_person(1)],
};

http.Response _json(Object? value, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(value)),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test(
    'HTTP uses the real user-search contract and public data only',
    () async {
      final client = ApiClient(
        idToken: () async => 'search-token',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/users');
          expect(request.url.queryParameters, {
            'q': 'Júlia',
            'pageNum': '0',
            'pageSize': '20',
          });
          expect(request.headers['Authorization'], 'Bearer search-token');
          expect(request.headers.containsKey('X-User-ID'), isFalse);
          return _json(_page());
        }),
      );
      addTearDown(client.close);
      final result = await HttpUserSearchRepository(apiClient: client)
          .searchUsers('  Júlia  ');
      expect(result.totalCount, 1);
      expect(result.nextPage, isNull);
      expect(result.users.single.username, 'julia1');
      expect(result.users.single.displayName, 'Júlia Riera');
      expect(result.users.single.avatarUrl, isNull);
      expect(() => result.users.clear(), throwsUnsupportedError);
    },
  );

  test(
    'Page continuation uses server total and safely encodes the query',
    () async {
      const query = 'a+ & %';
      final client = ApiClient(
        idToken: () async => 'token',
        client: MockClient((request) async {
          expect(request.url.queryParameters['q'], query);
          final page = int.parse(request.url.queryParameters['pageNum']!);
          return _json({
            'query': query,
            'page-num': page,
            'page-size': 1,
            'total': 2,
            'users': [_person(page + 1)],
          });
        }),
      );
      addTearDown(client.close);
      final repo = HttpUserSearchRepository(apiClient: client, pageSize: 1);
      expect((await repo.searchUsers(query)).nextPage, 1);
      expect((await repo.searchUsers(query, page: 1)).nextPage, isNull);
    },
  );

  test('Empty input and invalid input never make a request', () async {
    var calls = 0;
    final client = ApiClient(
      client: MockClient((_) async {
        calls++;
        return _json(_page());
      }),
    );
    addTearDown(client.close);
    final repo = HttpUserSearchRepository(apiClient: client);
    expect((await repo.searchUsers('  ')).users, isEmpty);
    await expectLater(repo.searchUsers('a', page: -1), throwsArgumentError);
    await expectLater(
      repo.searchUsers(List.filled(101, '😀').join()),
      throwsArgumentError,
    );
    await expectLater(
      repo.searchUsers('Júlia'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
    expect(calls, 0);
  });

  final malformed = <String, Map<String, Object?>>{
    'wrong query': {..._page(), 'query': 'another'},
    'wrong page': {..._page(), 'page-num': 1},
    'wrong size': {..._page(), 'page-size': 10},
    'negative total': {..._page(), 'total': -1},
    'missing list': {..._page()}..remove('users'),
    'invalid user': {
      ..._page(),
      'users': ['invalid'],
    },
    'invalid id': {
      ..._page(),
      'users': [
        {..._person(1), 'id': 'bad'},
      ],
    },
    'missing name': {
      ..._page(),
      'users': [
        {..._person(1)}..remove('name'),
      ],
    },
    'invalid username': {
      ..._page(),
      'users': [
        {..._person(1), 'username': ''},
      ],
    },
    'inconsistent total': {..._page(), 'total': 0},
    'missing results': {..._page(), 'users': []},
    'duplicate user': {
      ..._page(),
      'total': 2,
      'users': [_person(1), _person(1)],
    },
  };
  for (final entry in malformed.entries) {
    test('Malformed ${entry.key} is an error, not an empty result', () async {
      final client = ApiClient(
        idToken: () async => 'token',
        client: MockClient((_) async => _json(entry.value)),
      );
      addTearDown(client.close);
      await expectLater(
        HttpUserSearchRepository(apiClient: client).searchUsers('Júlia'),
        throwsFormatException,
      );
    });
  }

  test('HTTP failures remain failures', () async {
    final client = ApiClient(
      idToken: () async => 'token',
      client: MockClient((_) async => _json({'error': 'Forbidden'}, 403)),
    );
    addTearDown(client.close);
    await expectLater(
      HttpUserSearchRepository(apiClient: client).searchUsers('Júlia'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
    );
  });

  test('Missing display name and unusable image fall back safely', () async {
    final client = ApiClient(
      idToken: () async => 'token',
      client: MockClient(
        (_) async => _json({
          ..._page(),
          'users': [
            {..._person(1), 'name': '', 'profile-picture': 'javascript:bad'},
          ],
        }),
      ),
    );
    addTearDown(client.close);
    final person = (await HttpUserSearchRepository(
      apiClient: client,
    ).searchUsers('Júlia')).users.single;
    expect(person.displayName, 'julia1');
    expect(person.avatarUrl, isNull);
  });

  test('Demo results open the matching demo profile and paginate', () async {
    const repo = DemoUserSearchRepository(pageSize: 1);
    final profiles = DemoPublicProfileRepository(
      activityRepository: DemoActivityRepository(),
    );
    final first = await repo.searchUsers('a');
    expect(first.totalCount, 3);
    expect(first.nextPage, 1);
    final second = await repo.searchUsers('a', page: 1);
    expect(second.users.single.id, isNot(first.users.single.id));
    for (final person in [first.users.single, second.users.single]) {
      final profile = await profiles.getPublicProfile(person.id);
      expect(profile.profile.username, person.username);
    }
    expect(
      (await repo.searchUsers('  LAIA ')).users.single.id,
      'demo-laiasoler',
    );
    expect((await repo.searchUsers('  ')).users, isEmpty);
    expect((await repo.searchUsers('no-match')).totalCount, 0);
  });
}
