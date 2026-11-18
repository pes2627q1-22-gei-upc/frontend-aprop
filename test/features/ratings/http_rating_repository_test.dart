import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/ratings/data/http_rating_repository.dart';
import 'package:aprop/features/ratings/models/already_rated_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('posts {score} to /events/{id}/ratings', () async {
    late http.Request sent;
    final repository = HttpRatingRepository(
      apiClient: ApiClient(
        idToken: () async => 'token',
        client: MockClient((request) async {
          sent = request;
          return http.Response('{}', 201);
        }),
      ),
    );

    await repository.rate(userId: 'u', activityId: '7', score: 4);

    expect(sent.method, 'POST');
    expect(sent.url.path, '/events/7/ratings');
    expect(jsonDecode(sent.body), {'score': 4});
    expect(sent.headers['Authorization'], 'Bearer token');
  });

  test('maps 409 Conflict to AlreadyRatedException', () async {
    final repository = HttpRatingRepository(
      apiClient: ApiClient(
        client: MockClient((request) async => http.Response('{}', 409)),
      ),
    );

    await expectLater(
      repository.rate(userId: 'u', activityId: '7', score: 4),
      throwsA(isA<AlreadyRatedException>()),
    );
  });

  test('rethrows other HTTP errors such as 403', () async {
    final repository = HttpRatingRepository(
      apiClient: ApiClient(
        client: MockClient((request) async => http.Response('{}', 403)),
      ),
    );

    await expectLater(
      repository.rate(userId: 'u', activityId: '7', score: 4),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
      ),
    );
  });

  test('rejects scores outside 1-5 without calling the server', () async {
    var calls = 0;
    final repository = HttpRatingRepository(
      apiClient: ApiClient(
        client: MockClient((request) async {
          calls++;
          return http.Response('{}', 201);
        }),
      ),
    );

    await expectLater(
      repository.rate(userId: 'u', activityId: '7', score: 6),
      throwsRangeError,
    );
    expect(calls, 0);
  });
}
