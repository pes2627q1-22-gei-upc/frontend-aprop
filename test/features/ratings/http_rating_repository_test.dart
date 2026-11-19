import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/ratings/data/http_rating_repository.dart';
import 'package:aprop/features/ratings/models/already_rated_exception.dart';
import 'package:aprop/features/ratings/models/rating_not_found_exception.dart';
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

  HttpRatingRepository repositoryFor(
    int status, [
    void Function(http.Request)? onRequest,
  ]) {
    return HttpRatingRepository(
      apiClient: ApiClient(
        idToken: () async => 'token',
        client: MockClient((request) async {
          onRequest?.call(request);
          return http.Response(status == 204 ? '' : '{}', status);
        }),
      ),
    );
  }

  test('puts {score} to /events/{id}/ratings/me', () async {
    late http.Request sent;
    await repositoryFor(
      200,
      (r) => sent = r,
    ).updateRating(userId: 'u', activityId: '7', score: 2);

    expect(sent.method, 'PUT');
    expect(sent.url.path, '/events/7/ratings/me');
    expect(jsonDecode(sent.body), {'score': 2});
    expect(sent.headers['Authorization'], 'Bearer token');
  });

  test('deletes /events/{id}/ratings/me and accepts 204', () async {
    late http.Request sent;
    await repositoryFor(
      204,
      (r) => sent = r,
    ).deleteRating(userId: 'u', activityId: '7');

    expect(sent.method, 'DELETE');
    expect(sent.url.path, '/events/7/ratings/me');
  });

  test('maps 404 on edit and delete to RatingNotFoundException', () async {
    await expectLater(
      repositoryFor(404).updateRating(userId: 'u', activityId: '7', score: 2),
      throwsA(isA<RatingNotFoundException>()),
    );
    await expectLater(
      repositoryFor(404).deleteRating(userId: 'u', activityId: '7'),
      throwsA(isA<RatingNotFoundException>()),
    );
  });

  test('rethrows other errors on edit and delete', () async {
    await expectLater(
      repositoryFor(401).deleteRating(userId: 'u', activityId: '7'),
      throwsA(
        isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  });

  test('rejects an invalid score on edit without calling the server', () async {
    var calls = 0;
    await expectLater(
      repositoryFor(
        200,
        (_) => calls++,
      ).updateRating(userId: 'u', activityId: '7', score: 0),
      throwsRangeError,
    );
    expect(calls, 0);
  });
}
