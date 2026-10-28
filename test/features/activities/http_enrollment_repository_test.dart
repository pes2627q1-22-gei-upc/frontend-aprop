import 'dart:async';
import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/http_enrollment_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const userId = 'f53add44-367c-4c16-bbee-38878f3fed48';

  Map<String, Object?> event(int id) => {
    'id': id,
    'title': 'Activitat $id',
    'start-date': '2026-11-07T00:00:00Z',
    'categories': ['agenda:categories/teatre'],
  };

  test(
    'Dues pantalles que se subscriuen alhora reben totes dues les inscripcions',
    () async {
      // Inici i l'Agenda es subscriuen en obrir l'app, abans que arribi la
      // primera resposta.
      final responses = <Completer<http.Response>>[];
      final repository = HttpEnrollmentRepository(
        apiClient: ApiClient(
          client: MockClient((request) {
            final response = Completer<http.Response>();
            responses.add(response);
            return response.future;
          }),
        ),
      );
      addTearDown(repository.dispose);

      final home = repository.watchEnrolledActivityIds(userId).first;
      final agenda = repository.watchEnrolledActivityIds(userId).first;
      await Future<void>.delayed(Duration.zero);

      for (final response in responses) {
        response.complete(
          http.Response.bytes(utf8.encode(jsonEncode([event(2)])), 200),
        );
      }

      expect(await home.timeout(const Duration(seconds: 1)), {'2'});
      expect(await agenda.timeout(const Duration(seconds: 1)), {'2'});
    },
  );
}
