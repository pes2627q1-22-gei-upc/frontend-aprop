import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/assistant/models/assistant_message.dart';
import 'package:aprop/features/assistant/presentation/screens/assistant_screen.dart';
import 'package:aprop/features/assistant/presentation/view_models/assistant_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_assistant_repository.dart';

AssistantMessage _reply(
  String text, {
  AssistantScreenTarget? action,
  String id = 'r1',
}) => AssistantMessage.assistant(
  id: id,
  text: text,
  sentAt: DateTime(2026, 11, 7),
  action: action,
  rawSentAt: '2026-11-07T10:00:00.123456Z',
  conversationStartedAt: '2026-11-07T09:59:00Z',
);

void main() {
  late FakeAssistantRepository repository;
  late AssistantViewModel viewModel;
  final opened = <AssistantScreenTarget>[];

  setUp(() {
    repository = FakeAssistantRepository()..suggestions = ['Concerts a Girona'];
    viewModel = AssistantViewModel(repository: repository);
    opened.clear();
  });

  tearDown(() => viewModel.dispose());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: AssistantScreen(
        viewModel: viewModel,
        onActivitySelected: (_) {},
        onOpenScreen: opened.add,
      ),
    ),
  );

  testWidgets(
    'suggestion chips send a normal message and stay after the conversation starts',
    (tester) async {
      repository.onSendMessage = (_) async => _reply('Hola');
      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('Concerts a Girona'));
      await tester.pumpAndSettle();

      expect(repository.receivedQueries, ['Concerts a Girona']);
      expect(find.byType(ActionChip), findsOneWidget);
    },
  );

  testWidgets('thumbs send exact timestamps, show selection, replace rating', (
    tester,
  ) async {
    repository.onSendMessage = (_) async => _reply('Resposta');
    await pump(tester);
    await viewModel.sendMessage('hola');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('assistant-thumb-up-r1')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    expect(repository.feedbacks.single.sentAt, '2026-11-07T10:00:00.123456Z');
    expect(repository.feedbacks.single.startedAt, '2026-11-07T09:59:00Z');

    await tester.tap(find.byKey(const ValueKey('assistant-thumb-down-r1')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.thumb_down), findsOneWidget);
    expect(find.byIcon(Icons.thumb_up), findsNothing);
    expect(repository.feedbacks.map((f) => f.helpful), [true, false]);
  });

  testWidgets(
    'welcome text has no thumbs; 404 hides them; other errors toast',
    (tester) async {
      repository.onSendMessage = (_) async => _reply('Resposta');
      await pump(tester);
      expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);
      await viewModel.sendMessage('hola');
      await tester.pumpAndSettle();

      repository.feedbackError = ApiException('x', statusCode: 500);
      await tester.tap(find.byKey(const ValueKey('assistant-thumb-up-r1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('No hem pogut desar la valoració'), findsOne);
      expect(find.byIcon(Icons.thumb_up), findsNothing);

      repository.feedbackError = ApiException('x', statusCode: 404);
      await tester.tap(find.byKey(const ValueKey('assistant-thumb-up-r1')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);
    },
  );

  testWidgets('action shows a button that opens the screen', (tester) async {
    repository.onSendMessage = (_) async =>
        _reply('Ves al perfil', action: AssistantScreenTarget.profile);
    await pump(tester);
    await viewModel.sendMessage('on edito el perfil?');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Obre Perfil'));
    expect(opened, [AssistantScreenTarget.profile]);
  });

  test('unknown or unsupported screens produce no action', () {
    expect(AssistantScreenTarget.fromApi('settings'), isNotNull);
    expect(AssistantScreenTarget.fromApi('interest-test'), isNull);
    expect(AssistantScreenTarget.fromApi('mars'), isNull);
  });

  testWidgets('429 shows the rate-limit text with the retry button', (
    tester,
  ) async {
    repository.onSendMessage = (_) async =>
        throw ApiException('too many', statusCode: 429);
    await pump(tester);
    await viewModel.sendMessage('hola');
    await tester.pumpAndSettle();

    expect(find.text('Massa missatges, espera un minut'), findsOneWidget);
    expect(find.text('Tornar-ho a provar'), findsOneWidget);
  });

  testWidgets('scrolls to the newest message and survives 200% text', (
    tester,
  ) async {
    repository.onSendMessage = (q) async => _reply('Resposta llarga ' * 20);
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: AssistantScreen(viewModel: viewModel, onActivitySelected: (_) {}),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await viewModel.sendMessage('missatge $i');
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(position.pixels, position.maxScrollExtent);
    expect(position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('recommended activities are compact: several fit on screen', (
    tester,
  ) async {
    final activities = await DemoActivityRepository().getActivities();
    repository.onSendMessage = (_) async => AssistantMessage.assistant(
      id: 'many',
      text: 'He trobat plans',
      sentAt: DateTime(2026, 11, 7),
      recommendedActivities: activities.take(3).toList(),
    );
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester);
    await viewModel.sendMessage('plans');
    await tester.pumpAndSettle();

    for (final a in activities.take(3)) {
      final tile = find.byKey(ValueKey('assistant-card-many-${a.id}'));
      expect(tile, findsOneWidget);
      expect(tester.getSize(tile).height, lessThan(120));
    }
  });
}
