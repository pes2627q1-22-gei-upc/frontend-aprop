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

  group('Refresc periòdic (amb el rellotge de les proves)', () {
    /// Without [create]: the test disposes it so no timer is left running.
    ActivityChatViewModel polling() => ActivityChatViewModel(
      activityId: '1282',
      userId: 'me',
      repository: repository,
      pollInterval: const Duration(seconds: 5),
    );

    testWidgets('Els missatges nous arriben sols mentre el xat és obert', (
      tester,
    ) async {
      final model = polling();
      await model.load();
      await model.send('Hola!');
      repository.messages.add(
        chatMessage('Ens veiem allà', sentAt: DateTime(2026, 11, 20, 18, 31)),
      );

      await tester.pump(const Duration(seconds: 5));

      // El propi missatge no surt dues vegades.
      expect(model.messages.map((m) => m.text), ['Hola!', 'Ens veiem allà']);
      model.dispose();
    });

    testWidgets('Amb una xarxa lenta, els refrescos no s’encavalquen', (
      tester,
    ) async {
      final model = polling();
      await model.load();
      repository.requestedPages.clear();
      repository.pendingLoad = Completer<void>();

      // Tres tics mentre la primera petició encara no ha acabat.
      await tester.pump(const Duration(seconds: 15));
      expect(repository.requestedPages, [0]);

      repository.pendingLoad!.complete();
      await tester.pump();
      model.dispose();
    });

    testWidgets('En segon pla no demana res; en tornar, refresca de seguida', (
      tester,
    ) async {
      final model = polling();
      await model.load();
      repository.requestedPages.clear();

      model.pause();
      await tester.pump(const Duration(minutes: 1));
      expect(repository.requestedPages, isEmpty);

      repository.messages.add(
        chatMessage('Ja hi soc', sentAt: DateTime(2026, 11, 20, 19)),
      );
      model.resume();
      await tester.pump();
      expect(repository.requestedPages, [0]);
      expect(model.messages.single.text, 'Ja hi soc');

      await tester.pump(const Duration(seconds: 5));
      expect(repository.requestedPages, [0, 0]);
      model.dispose();
    });
  });

  test(
    'Si falla un refresc, els missatges es queden i no surt cap error',
    () async {
      repository.messages = [
        chatMessage('Hola', sentAt: DateTime(2026, 11, 20, 10)),
      ];
      create();
      await viewModel.load();

      repository.loadError = Exception('sense connexió');
      await viewModel.refresh();

      expect(viewModel.messages.single.text, 'Hola');
      expect(viewModel.errorMessage, isNull);
    },
  );

  test(
    'Si falla carregar els anteriors, ho diu i es pot tornar a provar',
    () async {
      repository.messages = [
        for (var i = 0; i < activityMessagePageSize + 5; i++)
          chatMessage(
            '$i',
            sentAt: DateTime(2026, 11, 20).add(Duration(minutes: i)),
          ),
      ];
      create();
      await viewModel.load();

      repository.loadError = Exception('sense connexió');
      await viewModel.loadOlder();
      expect(viewModel.olderError, isNotNull);
      expect(viewModel.messages, hasLength(activityMessagePageSize));

      repository.loadError = null;
      await viewModel.loadOlder();
      expect(viewModel.olderError, isNull);
      expect(viewModel.messages.first.text, '0');
    },
  );

  test(
    'Si n’han arribat de nous, «anteriors» encara porta els anteriors',
    () async {
      DateTime at(int minute) =>
          DateTime(2026, 11, 20).add(Duration(minutes: minute));
      repository.messages = [
        for (var i = 0; i < activityMessagePageSize + 5; i++)
          chatMessage('$i', sentAt: at(i)),
      ];
      create();
      await viewModel.load();
      // Arriben tres missatges nous i el refresc els afegeix.
      for (var i = 0; i < 3; i++) {
        repository.messages.add(
          chatMessage('nou $i', sentAt: at(activityMessagePageSize + 5 + i)),
        );
      }
      await viewModel.refresh();

      await viewModel.loadOlder();

      expect(viewModel.messages.first.text, '0');
      expect(viewModel.messages, hasLength(activityMessagePageSize + 8));
      expect(viewModel.hasOlder, isFalse);
    },
  );

  test(
    'Un text massa llarg es compta com el backend (runes) i no s’envia',
    () async {
      create();
      await viewModel.load();
      // 👍🏽 és un sol caràcter visible però dues runes.
      final tooLong = '👍🏽' * (maxActivityMessageLength ~/ 2 + 1);

      expect(await viewModel.send(tooLong), isFalse);

      expect(repository.sent, isEmpty);
      expect(
        viewModel.sendError,
        'El missatge és massa llarg. Fes-lo més curt.',
      );
    },
  );

  test(
    'Si el backend rebutja el text, no convida a tornar-ho a provar',
    () async {
      repository.sendError = const MessageRejectedException();
      create();
      await viewModel.load();

      expect(await viewModel.send('Hola'), isFalse);

      expect(
        viewModel.sendError,
        'El missatge és massa llarg. Fes-lo més curt.',
      );
    },
  );

  test(
    'Sense inscripció, el ViewModel ho indica per no oferir reintent',
    () async {
      repository.loadError = const NotEnrolledInChatException();
      create();

      await viewModel.load();

      expect(viewModel.isNotEnrolled, isTrue);
    },
  );
}
