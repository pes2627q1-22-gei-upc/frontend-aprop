import 'dart:async';

import 'package:aprop/features/activity_chat/presentation/view_models/activity_chat_view_model.dart';
import 'package:aprop/features/activity_chat/repositories/activity_chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_activity_chat_repository.dart';

void main() {
  late FakeActivityChatRepository repository;
  late ActivityChatViewModel viewModel;

  ActivityChatViewModel create({
    Duration pollInterval = const Duration(hours: 1),
  }) {
    viewModel = ActivityChatViewModel(
      activityId: '1282',
      userId: 'me',
      repository: repository,
      pollInterval: pollInterval,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  setUp(() => repository = FakeActivityChatRepository());

  test('Mostra l’historial en ordre cronològic', () async {
    repository.messages = [
      chatMessage('Primer', sentAt: DateTime(2026, 11, 20, 10)),
      chatMessage('Segon', sentAt: DateTime(2026, 11, 20, 11)),
    ];
    create();

    final load = viewModel.load();
    expect(viewModel.isLoading, isTrue);
    await load;

    expect(viewModel.messages.map((m) => m.text), ['Primer', 'Segon']);
    expect(viewModel.hasLoaded, isTrue);
    expect(viewModel.hasOlder, isFalse);
  });

  test('Un xat buit no és un error', () async {
    create();
    await viewModel.load();

    expect(viewModel.messages, isEmpty);
    expect(viewModel.errorMessage, isNull);
  });

  test('Sense inscripció, explica que cal apuntar-s’hi (R11)', () async {
    repository.loadError = const NotEnrolledInChatException();
    create();
    await viewModel.load();

    expect(viewModel.hasLoaded, isFalse);
    expect(
      viewModel.errorMessage,
      'Només les persones apuntades a l’activitat poden fer servir el xat.',
    );
  });

  test('Si falla la càrrega, es pot tornar a provar', () async {
    repository.loadError = Exception('sense xarxa');
    create();
    await viewModel.load();
    expect(viewModel.errorMessage, isNotNull);

    repository.loadError = null;
    await viewModel.load();
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.hasLoaded, isTrue);
  });

  test('Envia un missatge i el posa al final com a propi', () async {
    create();
    await viewModel.load();

    final sending = viewModel.send('  Hola a tothom!  ');
    expect(viewModel.isSending, isTrue);
    expect(await sending, isTrue);

    expect(repository.sent, ['Hola a tothom!']);
    expect(viewModel.messages.single.text, 'Hola a tothom!');
    expect(viewModel.isMine(viewModel.messages.single), isTrue);
    expect(viewModel.isSending, isFalse);
  });

  test('Un text buit no s’envia', () async {
    create();
    await viewModel.load();

    expect(await viewModel.send('   '), isFalse);
    expect(repository.sent, isEmpty);
  });

  test('Si l’enviament falla, ho diu i no perd el text', () async {
    repository.sendError = Exception('sense xarxa');
    create();
    await viewModel.load();

    expect(await viewModel.send('Hola!'), isFalse);
    expect(
      viewModel.sendError,
      'No s’ha pogut enviar el missatge. Torna-ho a provar.',
    );
    expect(viewModel.messages, isEmpty);
  });

  test('Els missatges nous arriben sols mentre el xat és obert', () async {
    create(pollInterval: const Duration(milliseconds: 20));
    await viewModel.load();
    await viewModel.send('Hola!');

    repository.messages.add(
      chatMessage('Ens veiem allà', sentAt: DateTime(2026, 11, 20, 18, 31)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 60));

    // El propi missatge no surt dues vegades.
    expect(viewModel.messages.map((m) => m.text), ['Hola!', 'Ens veiem allà']);
  });

  test('Carrega els missatges anteriors per pàgines', () async {
    repository.messages = [
      for (var i = 0; i < activityMessagePageSize + 5; i++)
        chatMessage(
          '$i',
          sentAt: DateTime(2026, 11, 20).add(Duration(minutes: i)),
        ),
    ];
    create();
    await viewModel.load();
    expect(viewModel.messages, hasLength(activityMessagePageSize));
    expect(viewModel.messages.first.text, '5');
    expect(viewModel.hasOlder, isTrue);

    await viewModel.loadOlder();

    expect(repository.requestedPages.last, 1);
    expect(viewModel.messages, hasLength(activityMessagePageSize + 5));
    expect(viewModel.messages.first.text, '0');
    expect(viewModel.hasOlder, isFalse);
  });

  test('Mentre s’envia, no se’n pot enviar un altre', () async {
    repository.pendingSend = Completer<void>();
    create();
    await viewModel.load();

    final first = viewModel.send('Un');
    expect(await viewModel.send('Dos'), isFalse);
    repository.pendingSend!.complete();
    expect(await first, isTrue);
    expect(repository.sent, ['Un']);
  });
}
