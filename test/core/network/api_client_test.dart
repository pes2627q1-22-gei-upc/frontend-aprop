import 'dart:convert';

import 'package:aprop/core/config/api_config.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiConfig', () {
    test('Apunta per defecte a Render i té un timeout de 60 segons', () {
      expect(ApiConfig.defaultBaseUrl, 'https://api-aprop.onrender.com');
      expect(ApiConfig.baseUrl, 'https://api-aprop.onrender.com');
      expect(ApiConfig.connectTimeout, const Duration(seconds: 60));
      expect(ApiConfig.isConfigured, isTrue);
    });
  });

  group('ApiClient', () {
    test('Injecta Accept, Content-Type i Authorization (sense X-User-ID) i resol la URI', () async {
      late http.Request capturedRequest;
      final client = ApiClient(
        baseUrl: Uri.parse('https://api-aprop.onrender.com/'),
        idToken: () async => 'token-firebase-123',
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response.bytes(
            utf8.encode(jsonEncode({'ok': true})),
            200,
          );
        }),
      );

      final result = await client.postJson(
        '/events/12/signup',
        queryParameters: {'source': 'app'},
        body: {'note': 'test'},
      );

      expect(
        capturedRequest.url.toString(),
        'https://api-aprop.onrender.com/events/12/signup?source=app',
      );
      expect(capturedRequest.headers['Accept'], 'application/json');
      expect(
        capturedRequest.headers['Content-Type'],
        startsWith('application/json'),
      );
      expect(
        capturedRequest.headers['Authorization'],
        'Bearer token-firebase-123',
      );
      // L'usuari surt del token: ja no s'envia cap altra identitat.
      expect(capturedRequest.headers.containsKey('X-User-ID'), isFalse);
      expect(result, {'ok': true});
    });

    test('Descodifica l’error estandarditzat {"error": "..."}', () async {
      final client = ApiClient(
        client: MockClient((_) async {
          return http.Response.bytes(
            utf8.encode(jsonEncode({'error': 'missing bearer token'})),
            401,
          );
        }),
      );

      await expectLater(
        client.getJson('events'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'missing bearer token'),
        ),
      );
    });

    test('Gestiona el timeout de cold start i les fallades de xarxa', () async {
      final timeoutClient = ApiClient(
        timeout: const Duration(milliseconds: 10),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        timeoutClient.getJson('events'),
        throwsA(
          isA<ApiException>().having((e) => e.isTimeout, 'isTimeout', isTrue),
        ),
      );

      final offlineClient = ApiClient(
        client: MockClient((_) => throw http.ClientException('offline')),
      );

      await expectLater(
        offlineClient.getJson('events'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isNetworkError,
            'isNetworkError',
            isTrue,
          ),
        ),
      );
    });
  });
}
