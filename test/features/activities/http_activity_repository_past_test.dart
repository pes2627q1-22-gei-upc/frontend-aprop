import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/http_activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'backend_event_fixture.dart';

void main() {
  test(
    'Finished events are hidden without stopping pagination (DP-082)',
    () async {
      final repository = HttpActivityRepository(
        clock: () => DateTime(2026, 9, 26, 9),
        apiClient: ApiClient(
          client: MockClient((request) async {
            // A full server page where one event is already over (clock: 2026-09-26).
            final body = [
              for (var i = 1; i <= 50; i++)
                i == 7
                    ? {...backendEvent(i), 'start-date': '2026-09-01T00:00:00Z'}
                    : backendEvent(i),
            ];
            return http.Response.bytes(
              utf8.encode(jsonEncode(body)),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );

      final page = await repository.getActivitiesPage();

      expect(page.items.length, 49);
      expect(page.items.any((a) => a.id == '7'), isFalse);
      expect(page.hasMore, isTrue);
    },
  );
}
