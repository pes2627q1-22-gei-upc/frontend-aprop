import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:aprop/features/auth/data/http_user_sync_repository.dart';
import 'package:aprop/features/auth/models/auth_failure.dart';

void main() {
  late http.Request lastRequest;

  HttpUserSyncRepository repositoryAnswering(
    int status, {
    Object? body,
    String? token = 'firebase-token',
    String baseUrl = 'http://10.0.2.2:8080',
  }) {
    return HttpUserSyncRepository(
      baseUrl: Uri.parse(baseUrl),
      idToken: () async => token,
      client: MockClient((request) async {
        lastRequest = request;
        return http.Response(jsonEncode(body ?? {}), status);
      }),
    );
  }

  const createdUser = {
    'user': {
      'id': 12,
      'firebase-uid': 'uid-1',
      'username': 'polvidal',
      'email': 'pol@aprop.cat',
    },
    'created': true,
  };

  test("Crea l'usuari amb el token de Firebase i el nom d'usuari", () async {
    final profile = await repositoryAnswering(
      201,
      body: createdUser,
    ).sync(username: 'polvidal');

    expect(lastRequest.method, 'POST');
    expect(lastRequest.url.toString(), 'http://10.0.2.2:8080/auth/sync');
    expect(lastRequest.headers['Authorization'], 'Bearer firebase-token');
    expect(jsonDecode(lastRequest.body), {'username': 'polvidal'});
    expect(profile?.id, '12');
    expect(profile?.username, 'polvidal');
    expect(profile?.email, 'pol@aprop.cat');
  });

  test("Sense nom d'usuari no envia cos i retorna l'usuari existent", () async {
    final profile = await repositoryAnswering(200, body: createdUser).sync();

    expect(lastRequest.body, isEmpty);
    expect(profile?.username, 'polvidal');
  });

  test('Accepta la URL base amb barra final', () async {
    await repositoryAnswering(
      200,
      body: createdUser,
      baseUrl: 'https://api.aprop.cat/',
    ).sync();

    expect(lastRequest.url.toString(), 'https://api.aprop.cat/auth/sync');
  });

  test("Retorna null si l'usuari encara no existeix (cal triar nom)", () async {
    final profile = await repositoryAnswering(
      422,
      body: {'error': 'invalid username'},
    ).sync();

    expect(profile, isNull);
  });

  test("Avisa si el nom d'usuari ja és d'una altra persona", () {
    expect(
      repositoryAnswering(
        409,
        body: {'error': 'username already taken'},
      ).sync(username: 'laiasoler'),
      throwsA(AuthFailure.usernameAlreadyInUse),
    );
  });

  test('Qualsevol altra resposta és un error inesperat', () {
    expect(
      repositoryAnswering(401, body: {'error': 'invalid token'}).sync(),
      throwsStateError,
    );
    expect(
      repositoryAnswering(422).sync(username: 'polvidal'),
      throwsStateError,
    );
  });

  test('Sense connexió avisa de la xarxa', () {
    final repository = HttpUserSyncRepository(
      baseUrl: Uri.parse('http://10.0.2.2:8080'),
      idToken: () async => 'firebase-token',
      client: MockClient((_) => throw http.ClientException('offline')),
    );

    expect(repository.sync(), throwsA(AuthFailure.network));
  });

  test('Sense sessió no fa cap petició', () {
    expect(repositoryAnswering(200, token: null).sync(), throwsStateError);
  });

  group('Nom i cognoms (PATCH /users/me)', () {
    late http.Request patch;

    HttpUserSyncRepository answering(int status, Object body) {
      return HttpUserSyncRepository(
        baseUrl: Uri.parse('http://10.0.2.2:8080'),
        idToken: () async => 'firebase-token',
        client: MockClient((request) async {
          patch = request;
          return http.Response.bytes(utf8.encode(jsonEncode(body)), status);
        }),
      );
    }

    test('Envia el nom amb el token i retorna el perfil', () async {
      final profile = await answering(200, {
        'id': 12,
        'username': 'polvidal',
        'name': 'Pol Martí Pujolà',
        'email': 'pol@aprop.cat',
      }).updateName('Pol Martí Pujolà');

      expect(patch.method, 'PATCH');
      expect(patch.url.toString(), 'http://10.0.2.2:8080/users/me');
      expect(patch.headers['Authorization'], 'Bearer firebase-token');
      expect(jsonDecode(patch.body), {'name': 'Pol Martí Pujolà'});
      // Els accents arriben bé encara que el backend no indiqui UTF-8.
      expect(profile.name, 'Pol Martí Pujolà');
      expect(profile.username, 'polvidal');
    });

    test('Si el backend el rebutja, és un error inesperat', () {
      expect(
        answering(400, {
          'error': 'name cannot exceed 100 characters',
        }).updateName('x' * 101),
        throwsStateError,
      );
    });

    test('Sense connexió avisa de la xarxa', () {
      final repository = HttpUserSyncRepository(
        baseUrl: Uri.parse('http://10.0.2.2:8080'),
        idToken: () async => 'firebase-token',
        client: MockClient((_) => throw http.ClientException('offline')),
      );

      expect(repository.updateName('Pol'), throwsA(AuthFailure.network));
    });
  });

  test('/auth/sync també llegeix el nom, amb accents', () async {
    final repository = HttpUserSyncRepository(
      baseUrl: Uri.parse('http://10.0.2.2:8080'),
      idToken: () async => 'firebase-token',
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'user': {
                'id': 3,
                'username': 'laia',
                'name': 'Laia Puigdomènech',
              },
              'created': false,
            }),
          ),
          200,
        ),
      ),
    );

    expect((await repository.sync())?.name, 'Laia Puigdomènech');
  });

  group('Eliminar compte (#10)', () {
    test(
      'Envia DELETE /users/me amb el token i el backend esborra Firebase',
      () async {
        final repository = repositoryAnswering(204);

        expect(await repository.deleteAccount(), isTrue);

        expect(lastRequest.method, 'DELETE');
        expect(lastRequest.url.path, '/users/me');
        expect(lastRequest.headers['Authorization'], 'Bearer firebase-token');
      },
    );

    test('Si ja no existia (404), el resultat és el mateix', () async {
      expect(await repositoryAnswering(404).deleteAccount(), isTrue);
    });

    test('Si el backend falla, no es dona per esborrat', () async {
      expect(
        repositoryAnswering(502).deleteAccount(),
        throwsA(isA<StateError>()),
      );
    });

    test('Sense connexió, és un error de xarxa', () async {
      final repository = HttpUserSyncRepository(
        baseUrl: Uri.parse('http://10.0.2.2:8080'),
        idToken: () async => 'firebase-token',
        client: MockClient((_) => throw http.ClientException('offline')),
      );

      expect(repository.deleteAccount(), throwsA(AuthFailure.network));
    });
  });
}
