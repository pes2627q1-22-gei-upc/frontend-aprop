import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/activity_json_mapper.dart';
import 'package:aprop/features/activities/data/http_activity_repository.dart';
import 'package:aprop/features/activities/presentation/formatters/activity_date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'backend_event_fixture.dart';

void main() {
  test('A missing server date is displayed as unknown rather than year 1', () {
    final activity = activityFromJson({
      ...backendEvent(1),
      'start-date': '0001-01-01T00:00:00Z',
    });
    expect(formatActivitySchedule(activity.startsAt), 'Data no informada');
    expect(
      formatActivitySchedule(activity.startsAt, includeDate: true),
      'Data no informada',
    );
  });
  http.Response json(Object? data, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    status,
    headers: {'content-type': 'application/json'},
  );

  test(
    'Uses zero-based pages and preserves the API order and headers',
    () async {
      final pages = <String?>[];
      final repo = HttpActivityRepository(
        apiClient: ApiClient(
          baseUrl: Uri.parse('https://api.example.test'),
          idToken: () async => 'test-token',
          client: MockClient((request) async {
            expect(request.url.path, '/events');
            expect(request.headers['Authorization'], 'Bearer test-token');
            // L'usuari surt del token: ja no s'envia X-User-ID.
            expect(request.headers.containsKey('X-User-ID'), isFalse);
            expect(request.url.queryParameters['pageSize'], '2');
            pages.add(request.url.queryParameters['pageNum']);
            return json(
              pages.length == 1
                  ? [backendEvent(2), backendEvent(1)]
                  : [backendEvent(3)],
            );
          }),
        ),
      );
      final first = await repo.getActivitiesPage(pageSize: 2);
      expect(first.items.map((a) => a.id), ['2', '1']);
      expect(first.hasMore, isTrue);
      final second = await repo.getActivitiesPage(page: 1, pageSize: 2);
      expect(second.items.single.id, '3');
      expect(second.hasMore, isFalse);
      expect(pages, ['0', '1']);
    },
  );

  test('An exact full page ends after a valid empty next page', () async {
    final repo = HttpActivityRepository(
      apiClient: ApiClient(
        client: MockClient(
          (request) async => json(
            request.url.queryParameters['pageNum'] == '0'
                ? [backendEvent(1)]
                : [],
          ),
        ),
      ),
    );
    expect((await repo.getActivitiesPage(pageSize: 1)).hasMore, isTrue);
    final end = await repo.getActivitiesPage(page: 1, pageSize: 1);
    expect(end.items, isEmpty);
    expect(end.hasMore, isFalse);
  });

  test(
    'Malformed success payloads are errors rather than empty catalogues',
    () async {
      for (final body in [
        null,
        {'unexpected': []},
        [null],
        [
          {'id': 1},
        ],
      ]) {
        final repo = HttpActivityRepository(
          apiClient: ApiClient(client: MockClient((_) async => json(body))),
        );
        await expectLater(repo.getActivitiesPage(), throwsFormatException);
      }
    },
  );

  test(
    'HTTP failures and malformed details stay distinct from a missing event',
    () async {
      for (final status in [401, 500]) {
        final repo = HttpActivityRepository(
          apiClient: ApiClient(
            client: MockClient(
              (_) async => json({'error': 'unavailable'}, status),
            ),
          ),
        );
        await expectLater(
          repo.getActivitiesPage(),
          throwsA(isA<ApiException>()),
        );
      }
      final missing = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((_) async => json({'error': 'not found'}, 404)),
        ),
      );
      expect(await missing.getActivityById('1'), isNull);
      final malformed = HttpActivityRepository(
        apiClient: ApiClient(client: MockClient((_) async => json([]))),
      );
      await expectLater(malformed.getActivityById('1'), throwsFormatException);
    },
  );

  test('Remote and relative Gencat covers are retained without losing commas in URLs', () {
    final absolute = activityFromJson({
      ...backendEvent(1),
      'image-url': 'https://cdn.example.test/cover.jpg?crop=10,20',
    });
    expect(absolute.imageUrl, 'https://cdn.example.test/cover.jpg?crop=10,20');
    expect(absolute.imageAsset, isEmpty);
    final relative = activityFromJson({
      ...backendEvent(2),
      'image-url': '',
      'images': '/content/dam/agenda/ca/Empordà festival.jpg,/content/dam/agenda/ca/other.jpg',
    });
    expect(
      relative.imageUrl,
      'https://agenda.cultura.gencat.cat/content/dam/agenda/ca/Empord%C3%A0%20festival.jpg',
    );
    expect(relative.municipality, 'Girona');
    expect(relative.startsAt, DateTime(2026, 11, 14));
  });

  test(
    'Absent or unsupported covers keep a placeholder; assets remain supported',
    () {
      for (final value in [
        '',
        'javascript:alert(1)',
        'file:///etc/passwd',
        'relative.jpg',
      ]) {
        final activity = activityFromJson({
          ...backendEvent(1),
          'images': value,
        });
        expect(activity.imageUrl, isNull);
        expect(activity.imageAsset, isEmpty);
      }
      expect(
        activityFromJson({
          ...backendEvent(1),
          'images': 'assets/images/jazz_al_parc.jpg',
        }).imageAsset,
        'assets/images/jazz_al_parc.jpg',
      );
      expect(
        () => activityFromJson({...backendEvent(1), 'start-date': 'invalid'}),
        throwsFormatException,
      );
    },
  );
}
