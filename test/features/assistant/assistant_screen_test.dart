import 'dart:async';

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/assistant/models/assistant_message.dart';
import 'package:aprop/features/assistant/presentation/screens/assistant_screen.dart';
import 'package:aprop/features/assistant/presentation/view_models/assistant_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_assistant_repository.dart';

void main() {
  late FakeAssistantRepository repository;
  late AssistantViewModel viewModel;

  setUp(() {
    repository = FakeAssistantRepository();
    viewModel = AssistantViewModel(repository: repository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  Widget buildSubject({ValueChanged<String>? onActivitySelected}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: AssistantScreen(
        viewModel: viewModel,
        onActivitySelected: onActivitySelected ?? (_) {},
      ),
    );
  }

  testWidgets(
    'Disables Enviar when input is empty and enables it when text is entered',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text(AssistantViewModel.welcomeText), findsOneWidget);
      expect(
        find.byTooltip('Entrada per veu disponible properament'),
        findsOneWidget,
      );

      final sendButtonFinder = find.widgetWithText(FilledButton, 'Enviar');
      expect(tester.widget<FilledButton>(sendButtonFinder).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('assistant-query-field')),
        '   ',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(sendButtonFinder).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('assistant-query-field')),
        'Música a Barcelona',
      );
      await tester.pump();
      expect(
        tester.widget<FilledButton>(sendButtonFinder).onPressed,
        isNotNull,
      );

      await tester.tap(sendButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Música a Barcelona'), findsOneWidget);
      expect(find.text('Resposta per a: Música a Barcelona'), findsOneWidget);
      expect(tester.widget<FilledButton>(sendButtonFinder).onPressed, isNull);
    },
  );

  testWidgets(
    'Shows loading state, interpreted criteria chips, and standard ActivityCard',
    (tester) async {
      final activities = await DemoActivityRepository().getActivities();
      final completer = Completer<AssistantMessage>();
      repository.onSendMessage = (_) => completer.future;

      String? selectedId;
      await tester.pumpWidget(
        buildSubject(onActivitySelected: (id) => selectedId = id),
      );

      await tester.enterText(
        find.byKey(const ValueKey('assistant-query-field')),
        'Jazz a Barcelona el 26 de setembre',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pump();

      expect(find.byKey(const ValueKey('assistant-typing')), findsOneWidget);

      completer.complete(
        AssistantMessage.assistant(
          id: 'reply-jazz',
          text: 'He trobat 1 activitat:',
          sentAt: DateTime(2026, 9, 26, 12),
          interpretation: const AssistantInterpretation(
            category: 'Música',
            municipality: 'Barcelona',
            dateRange: '26 set. 2026',
          ),
          recommendedActivities: [activities.first],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tipus: Música'), findsOneWidget);
      expect(find.text('Municipi: Barcelona'), findsOneWidget);
      expect(find.text('Dates: 26 set. 2026'), findsOneWidget);
      expect(find.text('Jazz al parc'), findsOneWidget);

      await tester.ensureVisible(find.text('Jazz al parc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jazz al parc'));
      await tester.pump();
      expect(selectedId, 'demo-jazz');
    },
  );

  testWidgets(
    'Shows error banner and retries when Tornar-ho a provar is tapped',
    (tester) async {
      var fail = true;
      repository.onSendMessage = (query) async {
        if (fail) throw Exception('boom');
        return AssistantMessage.assistant(
          id: 'ok',
          text: 'Ara sí: $query',
          sentAt: DateTime(2026, 9, 26, 12),
        );
      };

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
        find.byKey(const ValueKey('assistant-query-field')),
        'Exposicions',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No hem pogut obtenir les recomanacions de l’assistent. Torna-ho a provar.',
        ),
        findsOneWidget,
      );

      fail = false;
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Tornar-ho a provar'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Tornar-ho a provar'));
      await tester.pumpAndSettle();

      expect(find.text('Ara sí: Exposicions'), findsOneWidget);
    },
  );

  testWidgets('Renders without overflow at 320px width and 2.0x text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final activities = await DemoActivityRepository().getActivities();
    repository.onSendMessage = (_) async => AssistantMessage.assistant(
      id: 'reply-a11y',
      text: 'Resultat accessible',
      sentAt: DateTime(2026, 9, 26, 12),
      interpretation: const AssistantInterpretation(
        category: 'Teatre',
        municipality: 'Tarragona',
        dateRange: '27 set. 2026',
      ),
      recommendedActivities: [activities[2]],
    );

    await tester.pumpWidget(buildSubject());
    await tester.enterText(
      find.byKey(const ValueKey('assistant-query-field')),
      'Teatre a Tarragona',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    final listScrollable = find.descendant(
      of: find.byKey(const PageStorageKey<String>('assistant-messages')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Teatre sota les estrelles'),
      200,
      scrollable: listScrollable,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Resultat accessible'), findsOneWidget);
    expect(find.text('Teatre sota les estrelles'), findsOneWidget);
  });
}
