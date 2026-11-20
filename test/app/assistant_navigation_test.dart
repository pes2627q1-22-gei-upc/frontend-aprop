import 'dart:async';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/assistant/models/assistant_message.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/assistant/fake_assistant_repository.dart';
import 'app_navigation.dart';

Future<DemoAuthRepository> _pumpApp(
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
  await openMapTab(tester);
  return auth;
}

Future<void> _openAssistant(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FloatingActionButton, 'Assistent'));
  await tester.pumpAndSettle();
  expect(find.widgetWithText(AppBar, 'Assistent'), findsOneWidget);
  expect(find.byType(NavigationBar), findsNothing);
}

Future<void> _sendQuery(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('assistant-query-field')),
    'Quin pla em recomanes?',
  );
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
  await tester.pump();
}

void main() {
  for (final systemBack in [false, true]) {
    testWidgets(
      'Chat hides navigation and restores the map with ${systemBack ? 'system' : 'toolbar'} back',
      (tester) async {
        await _pumpApp(tester);
        // Una targeta oberta al mapa ha de continuar oberta en tornar.
        await tapMarker(tester, 'demo-jazz');
        expect(find.byTooltip('Tancar'), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);

        await _openAssistant(tester);

        if (!systemBack) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          expect(find.byType(NavigationBar), findsNothing);
          expect(
            tester
                .getBottomLeft(
                  find.byKey(const ValueKey('assistant-query-field')),
                )
                .dy,
            lessThanOrEqualTo(844 - 280),
          );
          expect(
            find.widgetWithText(FilledButton, 'Enviar').hitTestable(),
            findsOneWidget,
          );
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
        }

        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byTooltip('Tornar enrere'));
        }
        await tester.pumpAndSettle();
        expect(find.widgetWithText(AppBar, 'Assistent'), findsNothing);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          2, // Mapa
        );
        expect(find.byTooltip('Tancar'), findsOneWidget);
        expect(find.text('Jazz al parc'), findsOneWidget);
        await _openAssistant(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final target in [
    AssistantScreenTarget.agenda,
    AssistantScreenTarget.settings,
  ]) {
    testWidgets('Chat shortcut to ${target.name} restores navigation', (
      tester,
    ) async {
      final assistant = FakeAssistantRepository()
        ..onSendMessage = (_) async => AssistantMessage.assistant(
          id: 'shortcut-reply',
          text: 'Pots continuar des d’aquí.',
          sentAt: DateTime(2026, 11, 16, 14),
          action: target,
        );
      await _pumpApp(tester, assistant: assistant);
      await _openAssistant(tester);
      await _sendQuery(tester);
      await tester.pumpAndSettle();
      final action = find.byKey(
        const ValueKey('assistant-action-shortcut-reply'),
      );
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Assistent'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        target == AssistantScreenTarget.agenda ? 1 : 4,
      );
      expect(
        find.widgetWithText(
          AppBar,
          target == AssistantScreenTarget.agenda ? 'Agenda' : 'Configuració',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('A reply arriving after closing chat preserves navigation', (
    tester,
  ) async {
    final reply = Completer<AssistantMessage>();
    final assistant = FakeAssistantRepository()
      ..onSendMessage = (_) => reply.future;
    await _pumpApp(tester, assistant: assistant);
    await _openAssistant(tester);
    await _sendQuery(tester);
    await tester.tap(find.byTooltip('Tornar enrere'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    reply.complete(
      AssistantMessage.assistant(
        id: 'late-reply',
        text: 'Aquí tens una proposta cultural.',
        sentAt: DateTime(2026, 11, 16, 14),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await _openAssistant(tester);
    expect(find.text('Aquí tens una proposta cultural.'), findsOneWidget);
    expect(assistant.receivedQueries, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ending the session with chat open restores the login screen', (
    tester,
  ) async {
    final auth = await _pumpApp(tester);
    await _openAssistant(tester);
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Inicia sessió'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Assistent'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
