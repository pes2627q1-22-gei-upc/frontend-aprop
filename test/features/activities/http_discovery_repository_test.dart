import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/http_discovery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'backend_event_fixture.dart';

const discoveryAccount = 'discovery-test-account';
const discoveryUuid = '11111111-1111-4111-8111-111111111111';
const discoveryProfile = {
  'id': discoveryUuid,
  'firebase-uid': discoveryAccount,
};
const discoveryPreferences = [
  {
    'category-id': 1,
    'category-name': 'agenda:categories/musica',
    'weight': 1.2,
  },
];

http.Response discoveryJson(Object? body, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, Object?> searchPage(int page, {int total = 3, List<int>? ids}) => {
  'query': 'jazz',
  'page-num': page,
  'page-size': 2,
  'total': total,
  'events': [
    for (final id in ids ?? (page == 0 ? [1, 2] : [3])) backendEvent(id),
  ],
};

void main() {
  HttpDiscoveryRepository repository(
    Future<http.Response> Function(http.Request) handle, {
    Future<String?> Function()? token,
  }) {
    final client = ApiClient(
      client: MockClient(handle),
      idToken: token ?? () async => 'test-token',
    );
    addTearDown(client.close);
    return HttpDiscoveryRepository(apiClient: client, searchPageSize: 2);
  }

  test(
    'Uses the three real feed contracts and preserves server order and covers',
    () async {
      final paths = <String>[];
      final repo = repository((request) async {
        paths.add(request.url.path);
        expect(request.headers['Authorization'], 'Bearer test-token');
        expect(request.headers.containsKey('X-User-ID'), isFalse);
        switch (request.url.path) {
          case '/users/me':
            return discoveryJson(discoveryProfile);
          case '/preferences':
            return discoveryJson(discoveryPreferences);
          case '/events/recommended':
            expect(request.url.queryParameters, {
              'pageNum': '0',
              'pageSize': '5',
            });
            return discoveryJson([
              backendEvent(8),
              {
                ...backendEvent(3),
                'images': 'https://images.example.test/3.jpg',
              },
            ]);
          case '/events/popular':
            expect(request.url.queryParameters, {
              'pageNum': '0',
              'pageSize': '5',
            });
            return discoveryJson([
              {...backendEvent(5), 'is-official': false},
              backendEvent(7),
            ]);
          default:
            return discoveryJson({'error': 'unexpected'}, 404);
        }
      });
      final feed = await repo.getFeed(userId: discoveryAccount);
      expect(feed.recommended.map((a) => a.id), ['8', '3']);
      expect(feed.featured.map((a) => a.id), ['5', '7']);
      expect(
        feed.recommended.last.imageUrl,
        'https://images.example.test/3.jpg',
      );
      expect(feed.isPersonalized, isTrue);
      expect(feed.hasErrors, isFalse);
      expect(
        paths,
        containsAll([
          '/users/me',
          '/preferences',
          '/events/recommended',
          '/events/popular',
        ]),
      );
      expect(paths, isNot(contains('/events')));
      expect(() => feed.featured.clear(), throwsUnsupportedError);
    },
  );

  test(
    'No preferences is a distinct state and does not call recommendations',
    () async {
      final paths = <String>[];
      final repo = repository((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/users/me') {
          return discoveryJson(discoveryProfile);
        }
        if (request.url.path == '/preferences') return discoveryJson([]);
        return discoveryJson([backendEvent(1)]);
      });
      final feed = await repo.getFeed(userId: discoveryAccount);
      expect(feed.needsInterests, isTrue);
      expect(feed.recommended, isEmpty);
      expect(feed.featured, hasLength(1));
      expect(feed.isPersonalized, isFalse);
      expect(feed.hasErrors, isFalse);
      expect(paths, isNot(contains('/events/recommended')));
    },
  );

  test(
    'Each failed section is explicit while the other remains usable',
    () async {
      for (final failed in [
        '/preferences',
        '/events/recommended',
        '/events/popular',
      ]) {
        final repo = repository((request) async {
          if (request.url.path == '/users/me') {
            return discoveryJson(discoveryProfile);
          }
          if (request.url.path == failed) {
            return discoveryJson({'error': 'offline'}, 500);
          }
          if (request.url.path == '/preferences') {
            return discoveryJson(discoveryPreferences);
          }
          return discoveryJson([backendEvent(1)]);
        });
        final feed = await repo.getFeed(userId: discoveryAccount);
        expect(feed.hasErrors, isTrue);
        if (failed == '/events/popular') {
          expect(feed.featuredUnavailable, isTrue);
          expect(feed.recommended, hasLength(1));
        } else {
          expect(feed.recommendationsUnavailable, isTrue);
          expect(feed.needsInterests, isFalse);
          expect(feed.featured, hasLength(1));
        }
      }
    },
  );

  test('Malformed selection and preferences do not look like successful empty data', () async {
    for (final malformed in [
      null,
      {},
      [null],
    ]) {
      final repo = repository((request) async {
        if (request.url.path == '/users/me') {
          return discoveryJson(discoveryProfile);
        }
        if (request.url.path == '/preferences') return discoveryJson(malformed);
        return discoveryJson(malformed);
      });
      final feed = await repo.getFeed(userId: discoveryAccount);
      expect(feed.recommendationsUnavailable, isTrue);
      expect(feed.featuredUnavailable, isTrue);
      expect(feed.needsInterests, isFalse);
    }
  });

  test(
    'Missing, foreign and expired sessions cannot load a personalized feed',
    () async {
      var calls = 0;
      final noSession = repository((_) async {
        calls++;
        return discoveryJson([]);
      }, token: () async => null);
      await expectLater(
        noSession.getFeed(userId: discoveryAccount),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 0);
      final foreign = repository(
        (_) async => discoveryJson({
          ...discoveryProfile,
          'firebase-uid': 'someone-else',
        }),
      );
      await expectLater(
        foreign.getFeed(userId: discoveryAccount),
        throwsA(isA<ApiException>()),
      );
      final expired = repository(
        (request) async => request.url.path == '/users/me'
            ? discoveryJson(discoveryProfile)
            : discoveryJson({'error': 'expired'}, 401),
      );
      await expectLater(
        expired.getFeed(userId: discoveryAccount),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test(
    'A feed operation pins its bearer and a new account is checked afresh',
    () async {
      var token = 'first-token';
      final repo = repository((request) async {
        expect(request.headers['Authorization'], 'Bearer first-token');
        if (request.url.path == '/users/me') {
          token = 'second-token';
          return discoveryJson(discoveryProfile);
        }
        if (request.url.path == '/preferences') {
          return discoveryJson(discoveryPreferences);
        }
        return discoveryJson([backendEvent(1)]);
      }, token: () async => token);
      await repo.getFeed(userId: discoveryAccount);
      final next = repository((_) async => discoveryJson(discoveryProfile));
      await expectLater(
        next.getFeed(userId: 'new-account'),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test('Search starts at zero, returns the actual total and advances to the final page', () async {
    final pages = <int>[];
    final repo = repository((request) async {
      expect(request.url.path, '/events/search');
      expect(request.url.queryParameters['q'], 'jazz');
      final page = int.parse(request.url.queryParameters['pageNum']!);
      pages.add(page);
      return discoveryJson(searchPage(page));
    });
    final first = await repo.searchActivitiesPage('  jazz  ');
    expect(first.activities.map((a) => a.id), ['1', '2']);
    expect(first.totalCount, 3);
    expect(first.nextPage, 1);
    final last = await repo.searchActivitiesPage('jazz', page: first.nextPage!);
    expect(last.activities.single.id, '3');
    expect(last.nextPage, isNull);
    expect(pages, [0, 1]);
    expect(() => first.activities.clear(), throwsUnsupportedError);
  });

  test('Blank search makes no request and malformed pagination is never an empty success', () async {
    var calls = 0;
    final blank = repository((_) async {
      calls++;
      return discoveryJson({});
    });
    expect((await blank.searchActivitiesPage('  ')).totalCount, 0);
    expect(calls, 0);
    await expectLater(
      blank.searchActivitiesPage('jazz', page: -1),
      throwsArgumentError,
    );
    for (final payload in [
      null,
      [],
      {...searchPage(0), 'page-num': 1},
      {...searchPage(0), 'total': -1},
      {...searchPage(0), 'events': null},
      {
        ...searchPage(0),
        'events': [null],
      },
      {...searchPage(0), 'events': []},
    ]) {
      final repo = repository((_) async => discoveryJson(payload));
      await expectLater(
        repo.searchActivitiesPage('jazz'),
        throwsFormatException,
      );
    }
    final offline = repository(
      (_) async => discoveryJson({'error': 'offline'}, 503),
    );
    await expectLater(
      offline.searchActivitiesPage('jazz'),
      throwsA(isA<ApiException>()),
    );
  });
}
