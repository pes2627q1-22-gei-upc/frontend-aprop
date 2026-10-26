import 'dart:async';
import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/http_activity_repository.dart';
import 'package:aprop/features/activities/models/activity_filters.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'backend_event_fixture.dart';

http.Response json(Object? data, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(data)),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test(
    'Activity categories are a snapshot, independent of the caller list',
    () {
      final categories = ['Teatre'];
      final activity = Activity(
        id: '1',
        title: 'Example',
        category: 'Música',
        municipality: 'Girona',
        startsAt: DateTime(2026, 11, 14),
        imageAsset: '',
        source: ActivitySource.culturalAgenda,
        categories: categories,
      );
      categories.clear();
      expect(activity.categories, ['Teatre']);
      expect(ActivityFilters(categories: ['Teatre']).matches(activity), isTrue);
      expect(() => activity.categories.clear(), throwsUnsupportedError);
    },
  );
  test(
    'Civil date bounds are inclusive, including the DST change day',
    () async {
      final requests = <Uri>[];
      final repository = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((request) async {
            requests.add(request.url);
            return json([]);
          }),
        ),
      );
      await repository.getActivitiesPage(
        filters: ActivityFilters(
          dates: ActivityDateRange(
            start: DateTime(2026, 10, 25),
            end: DateTime(2026, 10, 26),
          ),
        ),
      );
      expect(requests.single.queryParameters, {
        'pageNum': '0',
        'pageSize': '50',
        'startAfter': '2026-10-25T00:00:00.000',
        'startBefore': '2026-10-26T00:00:00.000',
      });
      await repository.getActivitiesPage();
      expect(
        requests.last.queryParameters.keys,
        unorderedEquals(['pageNum', 'pageSize']),
      );
    },
  );

  test(
    'Metadata supplies real IDs and all categories, without invented aliases',
    () async {
      var categoryRequests = 0;
      final requestedIds = <String?>[];
      final repository = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((request) async {
            if (request.url.path == '/categories') {
              categoryRequests++;
              return json([
                {'id': 73, 'name': 'agenda:ambits/concerts'},
                {'id': 14, 'name': 'agenda:categories/musica'},
              ]);
            }
            requestedIds.add(request.url.queryParameters['filterCategory']);
            return json([backendEvent(1)]);
          }),
        ),
      );
      expect(await repository.getFilterCategories(), ['Concerts', 'Musica']);
      final filters = ActivityFilters(categories: ['Concerts']);
      final page = await repository.getActivitiesPage(filters: filters);
      expect(page.items.single.categories, ['Musica', 'Concerts']);
      expect(filters.applyTo(page.items), hasLength(1));
      await repository.getActivitiesPage(page: 1, filters: filters);
      expect(requestedIds, ['73', '73']);
      expect(categoryRequests, 1);
    },
  );

  test(
    'Multiple categories are OR queries on every page, with unique IDs',
    () async {
      final requests = <Map<String, String>>[];
      final repository = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((request) async {
            if (request.url.path == '/categories') {
              return json([
                {'id': 5, 'name': 'Teatre'},
                {'id': 2, 'name': 'Música'},
              ]);
            }
            final query = request.url.queryParameters;
            requests.add(query);
            if (query['pageNum'] == '1') return json([]);
            return json(
              query['filterCategory'] == '2'
                  ? [backendEvent(1), backendEvent(2)]
                  : [backendEvent(2)],
            );
          }),
        ),
      );
      final filters = ActivityFilters(
        categories: ['Teatre', 'Música'],
        dates: ActivityDateRange(start: DateTime(2026, 11, 14)),
      );
      final first = await repository.getActivitiesPage(
        pageSize: 2,
        filters: filters,
      );
      expect(first.items.map((event) => event.id), ['1', '2']);
      expect(first.hasMore, isTrue);
      final last = await repository.getActivitiesPage(
        page: 1,
        pageSize: 2,
        filters: filters,
      );
      expect(last.items, isEmpty);
      expect(last.hasMore, isFalse);
      expect(requests.map((q) => '${q['pageNum']}/${q['filterCategory']}'), [
        '0/2',
        '0/5',
        '1/2',
        '1/5',
      ]);
      for (final query in requests) {
        expect(query['startAfter'], '2026-11-14T00:00:00.000');
        expect(query['startBefore'], '2026-11-14T00:00:00.000');
      }
    },
  );

  test('Equal display labels retain every real category ID', () async {
    final requestedIds = <String?>[];
    final repository = HttpActivityRepository(
      apiClient: ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/categories') {
            return json([
              {'id': 3, 'name': 'agenda:categories/teatre'},
              {'id': 8, 'name': 'agenda:ambits/teatre'},
            ]);
          }
          requestedIds.add(request.url.queryParameters['filterCategory']);
          return json([]);
        }),
      ),
    );
    expect(await repository.getFilterCategories(), ['Teatre']);
    await repository.getActivitiesPage(
      filters: ActivityFilters(categories: ['Teatre']),
    );
    expect(requestedIds, ['3', '8']);
  });

  test(
    'A failing category fails the whole batch; retry requests the same page',
    () async {
      var fail = true;
      final requests = <String?>[];
      final repository = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((request) async {
            if (request.url.path == '/categories') {
              return json([
                {'id': 1, 'name': 'Música'},
                {'id': 2, 'name': 'Teatre'},
              ]);
            }
            requests.add(request.url.queryParameters['pageNum']);
            if (fail && request.url.queryParameters['filterCategory'] == '2') {
              return json({'error': 'offline'}, 503);
            }
            return json([backendEvent(1)]);
          }),
        ),
      );
      final filters = ActivityFilters(categories: ['Música', 'Teatre']);
      await expectLater(
        repository.getActivitiesPage(page: 2, filters: filters),
        throwsA(isA<ApiException>()),
      );
      fail = false;
      expect(
        (await repository.getActivitiesPage(page: 2, filters: filters)).items,
        hasLength(1),
      );
      expect(requests, ['2', '2', '2', '2']);
    },
  );

  test(
    'Unknown selections fail without broadening to an unfiltered query',
    () async {
      var eventRequests = 0;
      final repository = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((request) async {
            if (request.url.path == '/categories') {
              return json([
                {'id': 1, 'name': 'Concerts'},
              ]);
            }
            eventRequests++;
            return json([]);
          }),
        ),
      );
      await expectLater(
        repository.getActivitiesPage(
          filters: ActivityFilters(categories: ['Música']),
        ),
        throwsStateError,
      );
      expect(eventRequests, 0);
    },
  );

  test(
    'Metadata requests are shared, validated and retryable after failure',
    () async {
      var requests = 0;
      final pending = Completer<void>();
      final repository = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((request) async {
            requests++;
            await pending.future;
            return requests == 1
                ? json([
                    {'id': 0, 'name': 'Invalid'},
                  ])
                : json([]);
          }),
        ),
      );
      final first = expectLater(
        repository.getFilterCategories(),
        throwsFormatException,
      );
      final second = expectLater(
        repository.getFilterCategories(),
        throwsFormatException,
      );
      pending.complete();
      await Future.wait([first, second]);
      expect(requests, 1);
      expect(await repository.getFilterCategories(), isEmpty);
      expect(requests, 2);
    },
  );

  test('Category fan-out has bounded concurrency', () async {
    var active = 0;
    var maximum = 0;
    final gates = <Completer<void>>[];
    final repository = HttpActivityRepository(
      apiClient: ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/categories') {
            return json([
              for (var id = 1; id <= 6; id++)
                {'id': id, 'name': 'Category $id'},
            ]);
          }
          active++;
          if (active > maximum) maximum = active;
          final gate = Completer<void>();
          gates.add(gate);
          await gate.future;
          active--;
          return json([]);
        }),
      ),
    );
    final loading = repository.getActivitiesPage(
      filters: ActivityFilters(
        categories: [for (var id = 1; id <= 6; id++) 'Category $id'],
      ),
    );
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
}
