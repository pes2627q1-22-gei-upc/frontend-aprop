import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/attendance/data/http_attendance_repository.dart';
import 'package:aprop/features/attendance/data/remembered_attendance_repository.dart';
import 'package:aprop/features/attendance/data/shared_preferences_attendance_memory.dart';
import 'package:aprop/features/attendance/repositories/attendance_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object? body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

class _FakeAttendance implements AttendanceRepository {
  bool? stored;
  final sent = <bool?>[];

  @override
  Future<bool?> getAttendance({
    required String userId,
    required String activityId,
  }) async => stored;

  @override
  Future<void> setAttendance({
    required String userId,
    required String activityId,
    required bool? attended,
  }) async {
    sent.add(attended);
    // Like the API: only «went» can be read back.
    stored = attended == true ? true : null;
  }
}

class _BrokenMemory implements AttendanceMemory {
  @override
  Future<bool> saidNo({required String userId, required String activityId}) =>
      throw Exception('storage');

  @override
  Future<void> remember({
    required String userId,
    required String activityId,
    required bool saidNo,
  }) => throw Exception('storage');
}

void main() {
  group('HTTP', () {
    HttpAttendanceRepository repository(
      Future<http.Response> Function(http.Request) handle,
    ) => HttpAttendanceRepository(
      apiClient: ApiClient(
        idToken: () async => 'token',
        client: MockClient(handle),
      ),
    );

    test('Reads has-attended: true means went, false is unknown', () async {
      final went = repository((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/events/42/enrollment/attendance');
        expect(request.headers['Authorization'], 'Bearer token');
        return _json({'user-id': 'u', 'event-id': 42, 'has-attended': true});
      });
      expect(await went.getAttendance(userId: 'u', activityId: '42'), isTrue);

      final unknown = repository(
        (request) async => _json({'has-attended': false}),
      );
      expect(
        await unknown.getAttendance(userId: 'u', activityId: '42'),
        isNull,
      );
    });

    test('Sends the answer with PATCH, including «No»', () async {
      final bodies = <Object?>[];
      final repo = repository((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/events/42/enrollment/attendance');
        bodies.add(jsonDecode(request.body));
        return _json({'attendance': null});
      });

      await repo.setAttendance(userId: 'u', activityId: '42', attended: false);
      await repo.setAttendance(userId: 'u', activityId: '42', attended: true);

      expect(bodies, [
        {'attendance': false},
        {'attendance': true},
      ]);
    });

    test('Errors are errors, not «not answered»', () async {
      expect(
        repository((request) async => _json({'error': 'x'}, 500))
            .getAttendance(userId: 'u', activityId: '42'),
        throwsA(isA<ApiException>()),
      );
      expect(
        repository((request) async => _json({'nope': 1}))
            .getAttendance(userId: 'u', activityId: '42'),
        throwsFormatException,
      );
      expect(
        repository((request) async => _json({'error': 'x'}, 500))
            .setAttendance(userId: 'u', activityId: '42', attended: true),
        throwsA(isA<ApiException>()),
      );
    });

    test('The server’s refusals say why', () async {
      expect(
        repository(
          (request) async => _json({
            'error': 'attendance can only be set once the event has started',
          }, 409),
        ).setAttendance(userId: 'u', activityId: '42', attended: true),
        throwsA(AttendanceFailure.notStarted),
      );
      expect(
        repository(
          (request) async =>
              _json({'error': 'user is not enrolled in the event'}, 404),
        ).setAttendance(userId: 'u', activityId: '42', attended: true),
        throwsA(AttendanceFailure.notEnrolled),
      );
    });
  });

  group('The device remembers «No» (DP-068)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('«No» is read back as false; «Sí» and clearing forget it', () async {
      final server = _FakeAttendance();
      final repo = RememberedAttendanceRepository(
        inner: server,
        memory: const SharedPreferencesAttendanceMemory(),
      );

      await repo.setAttendance(userId: 'u', activityId: '42', attended: false);
      expect(server.sent, [false]);
      expect(await repo.getAttendance(userId: 'u', activityId: '42'), isFalse);
      // Another account on the same device has not answered.
      expect(await repo.getAttendance(userId: 'v', activityId: '42'), isNull);

      await repo.setAttendance(userId: 'u', activityId: '42', attended: true);
      expect(await repo.getAttendance(userId: 'u', activityId: '42'), isTrue);

      await repo.setAttendance(userId: 'u', activityId: '42', attended: null);
      expect(await repo.getAttendance(userId: 'u', activityId: '42'), isNull);
    });

    test(
      'A device that cannot remember asks again instead of failing',
      () async {
        final repo = RememberedAttendanceRepository(
          inner: _FakeAttendance(),
          memory: _BrokenMemory(),
        );

        await repo.setAttendance(
          userId: 'u',
          activityId: '42',
          attended: false,
        );

        expect(await repo.getAttendance(userId: 'u', activityId: '42'), isNull);
      },
    );
  });
}
