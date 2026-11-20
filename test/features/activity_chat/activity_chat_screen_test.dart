import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activity_chat/presentation/screens/activity_chat_screen.dart';
import 'package:aprop/features/activity_chat/repositories/activity_chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_activity_chat_repository.dart';

void main() {
  late FakeActivityChatRepository repository;

  Future<void> pumpChat(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ActivityChatScreen(
          activityId: '1282',
          activityTitle: 'Jazz al parc',
          userId: 'me',
          repository: repository,
          // Que el refresc no s'executi durant la prova.
          pollInterval: const Duration(hours: 1),
          now: () => DateTime(2026, 11, 20, 20),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => repository = FakeActivityChatRepository());

  testWidgets('Mostra l’historial amb l’autor i l’hora', (tester) async {
    repository.messages = [
      chatMessage('Hi anirem en bici!', sentAt: DateTime(2026, 11, 19, 9, 5)),
      chatMessage('Jo també', sentAt: DateTime(2026, 11, 20, 18, 30)),
    ];
    await pumpChat(tester);

    expect(find.text('Jazz al parc'), findsOneWidget);
    expect(find.text('Hi anirem en bici!'), findsOneWidget);
    expect(find.text('Jo també'), findsOneWidget);
    // El nom només surt una vegada per als missatges seguits.
    expect(find.text('Laia Soler'), findsOneWidget);
    expect(find.text('Ahir · 09.05 h'), findsOneWidget);
    expect(find.text('18.30 h'), findsOneWidget);
    // En ordre cronològic: el més antic, a dalt.
    expect(
      tester.getTopLeft(find.text('Hi anirem en bici!')).dy,
      lessThan(tester.getTopLeft(find.text('Jo també')).dy),
    );
  });

  testWidgets('Un xat buit convida a començar', (tester) async {
    await pumpChat(tester);

    expect(
      find.text(
        'Encara no hi ha missatges. Saluda les persones que hi aniran!',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Si no s’hi està apuntat, ho diu i no deixa escriure', (
    tester,
  ) async {
    repository.loadError = const NotEnrolledInChatException();
    await pumpChat(tester);

    expect(
      find.text(
        'Només les persones apuntades a l’activitat poden fer servir el xat.',
      ),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('Envia un missatge i buida el camp', (tester) async {
    await pumpChat(tester);
    final send = find.byTooltip('Enviar');
    IconButton sendButton() =>
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));
    // Amb el camp buit no es pot enviar.
    expect(sendButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Ens veiem a les 7!');
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(repository.sent, ['Ens veiem a les 7!']);
    expect(find.text('Ens veiem a les 7!'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('Si no s’envia, conserva el text i ho explica', (tester) async {
    repository.sendError = Exception('sense xarxa');
    await pumpChat(tester);

    await tester.enterText(find.byType(TextField), 'Hola!');
    await tester.pump();
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();

    expect(
      find.text('No s’ha pogut enviar el missatge. Torna-ho a provar.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Hola!',
    );
  });
}
