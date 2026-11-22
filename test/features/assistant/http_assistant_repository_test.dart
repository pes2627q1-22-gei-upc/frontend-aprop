import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/assistant/data/http_assistant_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('HttpAssistantRepository preserves exact order and count of recommended events', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/assistant/messages');
      return http.Response(
        jsonEncode({
          'conversation-started-at': '2026-11-21T10:00:00Z',
          'user-message': {
            'sent-at': '2026-11-21T10:00:00Z',
            'sender': 'user',
            'text': 'exposicions a Barcelona',
            'by-voice': false,
          },
          'assistant-message': {
            'sent-at': '2026-11-21T10:00:01Z',
            'sender': 'assistant',
            'text': 'Et recomano **Les parets criden**, **Exposició MACBA** i **Clave Gaudí**.',
            'by-voice': false,
            'interpretation': {
              'category': 'exposició',
              'municipality': 'Barcelona',
            },
            'recommended-events': [
              {
                'id': 20,
                'title': 'Les parets criden',
                'municipality': 'Barcelona',
                'start-date': '2026-11-21T00:00:00Z',
                'is-official': true,
              },
              {
                'id': 40,
                'title': 'Exposició MACBA',
                'municipality': 'Barcelona',
                'start-date': '2026-11-21T00:00:00Z',
                'is-official': true,
              },
              {
                'id': 50,
                'title': 'Clave Gaudí',
                'municipality': 'Barcelona',
                'start-date': '2026-11-21T00:00:00Z',
                'is-official': true,
              },
            ],
          },
        }),
        201,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final repo = HttpAssistantRepository(
      apiClient: ApiClient(
        baseUrl: Uri.parse('https://api.example.test'),
        client: client,
      ),
    );

    final reply = await repo.sendMessage('exposicions a Barcelona');
    expect(reply.recommendedActivities.map((a) => a.id).toList(), [
      '20',
      '40',
      '50',
    ]);
    expect(reply.recommendedActivities.map((a) => a.title).toList(), [
      'Les parets criden',
      'Exposició MACBA',
      'Clave Gaudí',
    ]);
    expect(reply.interpretation?.category, 'exposició');
    expect(reply.interpretation?.municipality, 'Barcelona');
  });

  test(
    'HttpAssistantRepository returns empty cards for clarifying questions',
    () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'conversation-started-at': '2026-11-21T10:00:00Z',
            'user-message': {
              'sent-at': '2026-11-21T10:00:00Z',
              'sender': 'user',
              'text': 'recomana plans',
              'by-voice': false,
            },
            'assistant-message': {
              'sent-at': '2026-11-21T10:00:01Z',
              'sender': 'assistant',
              'text': 'Quin tipus de pla et ve de gust i a quina ciutat?',
              'by-voice': false,
            },
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final repo = HttpAssistantRepository(
        apiClient: ApiClient(
          baseUrl: Uri.parse('https://api.example.test'),
          client: client,
        ),
      );

      final reply = await repo.sendMessage('recomana plans');
      expect(reply.recommendedActivities, isEmpty);
      expect(reply.interpretation, isNull);
    },
  );
}
