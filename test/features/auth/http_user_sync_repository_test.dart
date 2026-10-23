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
}
