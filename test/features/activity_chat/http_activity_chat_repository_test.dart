import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activity_chat/data/http_activity_chat_repository.dart';
import 'package:aprop/features/activity_chat/repositories/activity_chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<http.Request> requests;

  HttpActivityChatRepository repository(
    http.Response Function(http.Request request) respond,
  ) {
    requests = [];
    return HttpActivityChatRepository(
      apiClient: ApiClient(
        idToken: () async => 'test-token',
        client: MockClient((request) async {
          requests.add(request);
          return respond(request);
        }),
      ),
    );
  }

  http.Response json(Object? body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  Map<String, Object?> message({
    String name = 'Laia Soler',
    String text = 'Hi anirem en bici!',
  }) => {
    'user-id': '2891d65e-667c-4526-bb4a-64ec42691a2a',
    'username': 'laia',
    'name': name,
    'profile-picture': '',
    'event-id': 1282,
    'text': text,
    'date-sent': '2026-11-20T17:30:00Z',
  };

  test('Carrega una pàgina del xat amb l’autor i l’hora', () async {
    final page = await repository(
      (_) => json({
        'event-id': 1282,
        'total': 3,
        'page-num': 1,
        'page-size': 50,
        'messages': [message()],
      }),
    ).getMessages('1282', page: 1);

    final url = requests.single.url;
    expect(url.path, endsWith('/events/1282/messages'));
    expect(url.queryParameters, {'pageNum': '1', 'pageSize': '50'});
    expect(requests.single.headers['Authorization'], 'Bearer test-token');

    expect(page.total, 3);
    final received = page.messages.single;
    expect(received.authorId, '2891d65e-667c-4526-bb4a-64ec42691a2a');
    expect(received.authorName, 'Laia Soler');
    expect(received.text, 'Hi anirem en bici!');
    expect(received.sentAt, DateTime.utc(2026, 11, 20, 17, 30).toLocal());
  });

  test('Sense nom, l’autor és el nom d’usuari', () async {
    final page = await repository(
      (_) => json({
        'total': 1,
        'messages': [message(name: '')],
      }),
    ).getMessages('1282');

    expect(page.messages.single.authorName, 'laia');
  });

  test('Envia el text i retorna el missatge desat', () async {
    final sent = await repository((_) => json(message(text: 'Hola!'), 201))
        .sendMessage('1282', 'Hola!');

    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, endsWith('/events/1282/messages'));
    expect(jsonDecode(requests.single.body), {'text': 'Hola!'});
    expect(sent.text, 'Hola!');
  });

  test('Qui no s’hi ha apuntat rep NotEnrolledInChatException (R11)', () {
    final repo = repository(
      (_) => json({'error': 'only users signed up'}, 403),
    );

    expect(
      repo.getMessages('1282'),
      throwsA(isA<NotEnrolledInChatException>()),
    );
    expect(
      repo.sendMessage('1282', 'Hola!'),
      throwsA(isA<NotEnrolledInChatException>()),
    );
  });

  test('Els altres errors del backend es propaguen', () {
    expect(
      repository((_) => json({'error': 'boom'}, 500)).getMessages('1282'),
      throwsA(isA<ApiException>()),
    );
  });

  test('Un missatge mal format no amaga la resta de la pàgina', () async {
    final repo = repository(
      (_) => json({
        'messages': [
          message(text: 'Bé'),
          {...message(text: 'Sense data'), 'date-sent': null},
          {...message(text: 'Data dolenta'), 'date-sent': 'ahir'},
          'no és un missatge',
        ],
        'total': 4,
      }),
    );

    final page = await repo.getMessages('1282');

    expect(page.messages.map((m) => m.text), ['Bé']);
  });

  test(
    'Si el backend rebutja el text (400), no és un error per reintentar',
    () async {
      final repo = repository(
        (_) => json({'error': 'text must be 1-1000 characters'}, 400),
      );

      expect(
        repo.sendMessage('1282', 'Hola'),
        throwsA(isA<MessageRejectedException>()),
      );
    },
  );

  test('Un missatge enviat sense data vàlida és un error', () async {
    final repo = repository((_) => json({...message(), 'date-sent': 'ahir'}));

    expect(repo.sendMessage('1282', 'Hola'), throwsA(isA<ApiException>()));
  });
}
