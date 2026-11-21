import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/http_activity_repository.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:aprop/features/activities/repositories/activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_enrollment_repository.dart';

http.Response _json(Object? body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('POST /events/{id}/cancel (#46)', () {
    HttpActivityRepository repository(
      Future<http.Response> Function(http.Request) handle,
    ) => HttpActivityRepository(
      apiClient: ApiClient(
        idToken: () async => 'token',
        client: MockClient(handle),
      ),
    );

    test('Cancels with the session token', () async {
      late http.Request received;
      final repo = repository((request) async {
        received = request;
        return _json({
          'event-id': 506,
          'state': 'Cancelled',
          'notified-users': 3,
        });
      });

      await repo.cancelActivity('506');

      expect(received.method, 'POST');
      expect(received.url.path, '/events/506/cancel');
      expect(received.headers['Authorization'], 'Bearer token');
    });

    test('Already cancelled (409 «not active») counts as cancelled', () async {
      final repo = repository(
        (request) async => _json({'error': 'event is not active'}, 409),
      );

      await repo.cancelActivity('506');
    });

    test('The server’s refusals become clear reasons', () async {
      for (final (status, text, expected) in [
        (409, 'event has already finished', ActivityCancelFailure.finished),
        (
          403,
          'only the creator can modify this event',
          ActivityCancelFailure.notAllowed,
        ),
        (422, 'event is invalid', ActivityCancelFailure.notAllowed),
      ]) {
        final repo = repository(
          (request) async => _json({'error': text}, status),
        );
        await expectLater(
          repo.cancelActivity('506'),
          throwsA(expected),
          reason: '$status $text',
        );
      }
    });

    test('Other failures are errors', () async {
      final repo = repository((request) async => _json({'error': 'x'}, 500));

      expect(repo.cancelActivity('506'), throwsA(isA<ApiException>()));
    });
  });

  test('Nobody can join a cancelled activity', () async {
    final enrollments = FakeEnrollmentRepository();
    addTearDown(enrollments.dispose);
    final model = EnrollmentViewModel(userId: 'u', repository: enrollments);
    addTearDown(model.dispose);
    await model.load();

    model.markCancelled('a1');
    await model.enroll('a1');

    expect(model.isCancelled('a1'), isTrue);
    expect(enrollments.enrolledRequests, isEmpty);
  });
}
