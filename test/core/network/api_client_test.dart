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
    test(
      'Injecta Accept, Content-Type, Authorization i X-User-ID i resol la URI',
      () async {
        late http.Request capturedRequest;
        final client = ApiClient(
          baseUrl: Uri.parse('https://api-aprop.onrender.com/'),
          idToken: () async => 'token-firebase-123',
          userId: () => 'uid-firebase-456',
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
        expect(capturedRequest.headers['X-User-ID'], 'uid-firebase-456');
        expect(result, {'ok': true});
      },
    );

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

    test(
      'Normalitza identificadors d’usuari a UUID canònic determinista quan cal',
      () {
        const validUuid = '550e8400-e29b-41d4-a716-446655440000';
        expect(ApiClient.isCanonicalUuid(validUuid), isTrue);
        expect(ApiClient.toCanonicalUuid(validUuid), validUuid);

        final generated = ApiClient.toCanonicalUuid('firebase-uid-28chars-xyz');
        expect(ApiClient.isCanonicalUuid(generated), isTrue);
        expect(
          ApiClient.toCanonicalUuid('firebase-uid-28chars-xyz'),
          generated,
        );
      },
    );
  });
}
