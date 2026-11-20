import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/assistant/models/assistant_message.dart';
import 'package:aprop/features/activities/presentation/widgets/activities_header.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/assistant/fake_assistant_repository.dart';
import 'app_navigation.dart';

/// #273: Inici mostra Descobreix i el mapa té la seva pestanya.
void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    FakeAssistantRepository? assistant,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    await tester.pumpWidget(
      APropApp(authRepository: auth, assistantRepository: assistant),
    );
    await tester.pumpAndSettle();
  }

  NavigationBar navigationBar(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar));

  testWidgets('En entrar es veu Inici amb les recomanacions', (tester) async {
    await pumpApp(tester);

    expect(navigationBar(tester).selectedIndex, 0);
    // Capçalera «AProp!» amb el «+» a l'esquerra i la cerca a la dreta.
    final appBar = find.byType(AppBar);
    expect(
      find.descendant(of: appBar, matching: find.bySemanticsLabel('AProp!')),
      findsOneWidget,
    );
    final create = find.byTooltip('Crear activitat');
    final search = find.byKey(const ValueKey('discover-search'));
    expect(create, findsOneWidget);
    expect(search, findsOneWidget);
    expect(tester.getCenter(create).dx, lessThan(tester.getCenter(search).dx));
    expect(find.text('Assistent'), findsOneWidget);
    // El mapa i la llista no hi són.
    expect(find.byType(ActivitiesHeader), findsNothing);
  });

  testWidgets('Les pestanyes es diuen Inici i Mapa', (tester) async {
    await pumpApp(tester);

    final labels = [
      for (final destination in tester.widgetList<NavigationDestination>(
        find.byType(NavigationDestination),
      ))
        destination.label,
    ];
    expect(labels, ['Inici', 'Agenda', 'Mapa', 'Avisos', 'Perfil']);
  });

  testWidgets('El mapa té la seva pestanya, amb l’assistent i sense «+»', (
    tester,
  ) async {
    await pumpApp(tester);
    await openMapTab(tester);

    expect(navigationBar(tester).selectedIndex, 2);
    expect(find.byType(ActivitiesHeader), findsOneWidget);
    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);
    expect(find.text('Assistent'), findsOneWidget);
    expect(find.byTooltip('Crear activitat'), findsNothing);
  });

  testWidgets('La cerca s’obre des de la capçalera d’Inici', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('discover-search')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Cerca'), findsOneWidget);
    expect(navigationBar(tester).selectedIndex, 0);
  });

  Future<void> openAssistant(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Assistent'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Assistent'), findsOneWidget);
  }

  testWidgets('L’assistent no tapa l’última targeta d’Inici', (tester) async {
    await pumpApp(tester);

    await tester.drag(
      find.byKey(const PageStorageKey('discover-feed')),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();

    // Al final del feed, l'última targeta acaba per sobre del botó.
    final lastCard = find.byKey(
      const ValueKey('discover-featured-demo-theatre'),
    );
    final assistant = find.widgetWithText(FloatingActionButton, 'Assistent');
    expect(
      tester.getBottomLeft(lastCard).dy,
      lessThanOrEqualTo(tester.getTopLeft(assistant).dy),
    );
    expect(
      find
          .descendant(of: lastCard, matching: find.text('M’hi apunto'))
          .hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('L’assistent obert des d’Inici hi torna en tancar-lo', (
    tester,
  ) async {
    await pumpApp(tester);

    await openAssistant(tester);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byTooltip('Tornar enrere'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Assistent'), findsNothing);
    expect(navigationBar(tester).selectedIndex, 0);
    expect(find.byKey(const ValueKey('discover-search')), findsOneWidget);
  });

  testWidgets(
    'Un enllaç a Descobreix des de l’assistent del Mapa porta a Inici',
    (tester) async {
      final assistant = FakeAssistantRepository()
        ..onSendMessage = (_) async => AssistantMessage.assistant(
          id: 'shortcut-reply',
          text: 'Mira les recomanacions.',
          sentAt: DateTime(2026, 11, 20, 14),
          action: AssistantScreenTarget.discover,
        );
      await pumpApp(tester, assistant: assistant);
      await openMapTab(tester);
      await openAssistant(tester);
      await tester.enterText(
        find.byKey(const ValueKey('assistant-query-field')),
        'Què em recomanes?',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();
      final action = find.byKey(
        const ValueKey('assistant-action-shortcut-reply'),
      );
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Assistent'), findsNothing);
      expect(navigationBar(tester).selectedIndex, 0);
      expect(find.byKey(const ValueKey('discover-search')), findsOneWidget);

      // El Mapa queda a l'arrel, sense la ruta de l'assistent.
      await openMapTab(tester);
      expect(find.widgetWithText(AppBar, 'Assistent'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(ActivitiesHeader), findsOneWidget);
    },
  );
}
