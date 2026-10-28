import 'dart:async';

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/presentation/formatters/notification_formatter.dart';
import 'package:aprop/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_repository.dart';
import 'notification_test_data.dart';

void main() {
  late FakeNotificationRepository repository;
  late List<String> activities;
  late List<String> people;
  setUp(() {
    repository = FakeNotificationRepository(
      inboxes: {
        'user-a': [
          requestNotice(),
          eventNotice(),
          eventNotice(
            id: 'reminder',
            type: NotificationType.reminder,
            receivedAt: DateTime(2026, 9, 26, 18),
            isRead: true,
          ),
        ],
      },
    );
    activities = [];
    people = [];
  });
  Future<void> pumpScreen(
    WidgetTester tester, {
    bool profileAvailable = false,
    double textScale = 1,
    Size size = const Size(390, 844),
    bool settle = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('Avisos')),
          body: NotificationsScreen(
            userId: 'user-a',
            repository: repository,
            onActivitySelected: activities.add,
            onPersonSelected: profileAvailable ? people.add : null,
            now: () => notificationNow,
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Finder filter(String name) =>
      find.byKey(ValueKey('notification-filter-$name'));
  Finder unread(String id) => find.byKey(ValueKey('notification-unread-$id'));
  Future<void> select(WidgetTester tester, String name) async {
    await tester.ensureVisible(filter(name));
    await tester.tap(filter(name));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Each filter starts at its own position and retains it when returning',
    (tester) async {
      repository.inboxes['user-a'] = [
        for (var index = 0; index < 20; index++)
          eventNotice(
            id: 'event-$index',
            receivedAt: notificationNow.subtract(Duration(minutes: index)),
            type: index.isEven
                ? NotificationType.recommendation
                : NotificationType.reminder,
          ),
      ];
      await pumpScreen(tester);
      final list = find.byType(ListView);
      double offset() => tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      await tester.drag(list, const Offset(0, -500));
      await tester.pumpAndSettle();
      final allOffset = offset();
      expect(allOffset, greaterThan(0));
      await select(tester, 'recommendations');
      expect(offset(), 0);
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
      final recommendationsOffset = offset();
      await select(tester, 'all');
      expect(offset(), allOffset);
      await select(tester, 'recommendations');
      expect(offset(), recommendationsOffset);
    },
  );

  testWidgets(
    'Generic social and unknown notices show no simulated friendship actions',
    (tester) async {
      repository.inboxes['user-a'] = [
        AppNotification.received(
          id: 'social',
          type: NotificationType.socialUpdate,
          receivedAt: notificationNow,
          isRead: false,
        ),
        AppNotification.received(
          id: 'unknown',
          type: NotificationType.other,
          receivedAt: notificationNow,
          isRead: false,
        ),
      ];
      await pumpScreen(tester);
      expect(find.text('Acceptar'), findsNothing);
      expect(find.text('Rebutjar'), findsNothing);
      expect(find.text('Tens un nou avís.'), findsOneWidget);
      await select(tester, 'social');
      expect(find.text('Tens un nou avís social.'), findsOneWidget);
      expect(find.text('Tens un nou avís.'), findsNothing);
      await tester.tap(find.text('Tens un nou avís social.'));
      await tester.pumpAndSettle();
      expect(unread('social'), findsNothing);
      expect(activities, isEmpty);
      expect(people, isEmpty);
      expect(repository.responses, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'A deleted activity notice remains readable without a dead link',
    (tester) async {
      repository.inboxes['user-a'] = [
        AppNotification.received(
          id: 'missing',
          type: NotificationType.reminder,
          receivedAt: notificationNow,
          isRead: false,
          activityId: '7',
          activityUnavailable: true,
        ),
      ];
      await pumpScreen(tester);
      expect(find.text('L’activitat ja no està disponible.'), findsOneWidget);
      await tester.tap(find.text('Tens un recordatori cultural.'));
      await tester.pumpAndSettle();
      expect(repository.reads, ['user-a/missing']);
      expect(activities, isEmpty);
      expect(unread('missing'), findsNothing);
    },
  );

  testWidgets('Failed activity context remains accessible with doubled text', (
    tester,
  ) async {
    repository.inboxes['user-a'] = [
      AppNotification.received(
        id: 'retry',
        type: NotificationType.recommendation,
        receivedAt: notificationNow,
        isRead: false,
        activityId: '7',
      ),
    ];
    await pumpScreen(tester, textScale: 2, size: const Size(320, 640));
    final message = find.text('Tens una recomanació cultural.');
    await tester.ensureVisible(message);
    await tester.pumpAndSettle();
    await tester.tap(message);
    await tester.pumpAndSettle();
    expect(activities, ['7']);
    expect(unread('retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Shows the four filters, chronological groups and unread state without reading',
    (tester) async {
      await pumpScreen(tester);
      for (final label in ['Tots', 'Social', 'Recordatoris', 'Recomanacions']) {
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
      expect(find.text('Avui'), findsOneWidget);
      expect(find.text('Ahir'), findsOneWidget);
      expect(find.text('Assistent'), findsNothing);
      expect(unread('request'), findsOneWidget);
      expect(unread('reminder'), findsNothing);
      expect(repository.reads, isEmpty);
      await select(tester, 'social');
      expect(find.text(notificationMessage(requestNotice())), findsOneWidget);
      expect(find.text(notificationMessage(eventNotice())), findsNothing);
      expect(repository.reads, isEmpty);
      expect(repository.responses, isEmpty);
    },
  );

  testWidgets(
    'Opening an activity confirms reading before invoking its callback',
    (tester) async {
      await pumpScreen(tester);
      await select(tester, 'recommendations');
      final pending = Completer<void>();
      repository.onRead = () => pending.future;
      final message = find.text(notificationMessage(eventNotice()));
      await tester.tap(message);
      await tester.pump();
      expect(activities, isEmpty);
      expect(unread('recommendation'), findsOneWidget);
      pending.complete();
      await tester.pumpAndSettle();
      expect(activities, ['demo-jazz']);
      expect(unread('recommendation'), findsNothing);
      expect(find.text('M’hi apunto'), findsNothing);
    },
  );

  testWidgets(
    'Opening a request with a real profile callback reads but does not accept',
    (tester) async {
      await pumpScreen(tester, profileAvailable: true);
      await tester.tap(find.text(notificationMessage(requestNotice())));
      await tester.pumpAndSettle();
      expect(people, ['person-marc']);
      expect(unread('request'), findsNothing);
      expect(find.text('Acceptar'), findsOneWidget);
      expect(repository.responses, isEmpty);
    },
  );

  testWidgets(
    'Unavailable profile is explicit and reading still does not resolve the request',
    (tester) async {
      await pumpScreen(tester);
      expect(find.text('Perfil disponible properament'), findsOneWidget);
      await tester.tap(find.text(notificationMessage(requestNotice())));
      await tester.pumpAndSettle();
      expect(people, isEmpty);
      expect(unread('request'), findsNothing);
      expect(find.text('Acceptar'), findsOneWidget);
    },
  );

  for (final accept in [true, false]) {
    testWidgets(
      'Response waits for confirmation and replaces both actions: $accept',
      (tester) async {
        await pumpScreen(tester);
        await select(tester, 'social');
        final pending = Completer<FriendRequestStatus>();
        repository.onRespond = () => pending.future;
        await tester.tap(find.text(accept ? 'Acceptar' : 'Rebutjar'));
        await tester.pump();
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(unread('request'), findsOneWidget);
        await tester.tap(find.text(accept ? 'Rebutjar' : 'Acceptar'));
        expect(repository.responses, hasLength(1));
        pending.complete(
          accept ? FriendRequestStatus.accepted : FriendRequestStatus.rejected,
        );
        await tester.pumpAndSettle();
        expect(
          find.text(accept ? 'Sol·licitud acceptada' : 'Sol·licitud rebutjada'),
          findsOneWidget,
        );
        expect(find.text('Acceptar'), findsNothing);
        expect(find.text('Rebutjar'), findsNothing);
        expect(unread('request'), findsNothing);
        expect(people, isEmpty);
        expect(activities, isEmpty);
      },
    );
  }

  testWidgets('Read failure retains the unread indicator and can be retried', (
    tester,
  ) async {
    await pumpScreen(tester);
    await select(tester, 'recommendations');
    repository.onRead = () async => throw StateError('Offline');
    await tester.tap(find.text(notificationMessage(eventNotice())));
    await tester.pumpAndSettle();
    expect(activities, isEmpty);
    expect(unread('recommendation'), findsOneWidget);
    expect(
      find.text('No hem pogut marcar l’avís com a llegit. Torna-ho a provar.'),
      findsOneWidget,
    );
    repository.onRead = null;
    await tester.tap(find.text(notificationMessage(eventNotice())));
    await tester.pumpAndSettle();
    expect(activities, ['demo-jazz']);
    expect(unread('recommendation'), findsNothing);
  });

  testWidgets('Response failure keeps both actions available for retry', (
    tester,
  ) async {
    await pumpScreen(tester);
    await select(tester, 'social');
    repository.onRespond = () async => throw StateError('Offline');
    await tester.tap(find.text('Acceptar'));
    await tester.pumpAndSettle();
    expect(
      find.text('No hem pogut respondre la sol·licitud. Torna-ho a provar.'),
      findsOneWidget,
    );
    expect(find.text('Acceptar'), findsOneWidget);
    repository.onRespond = null;
    await tester.tap(find.text('Acceptar'));
    await tester.pumpAndSettle();
    expect(find.text('Sol·licitud acceptada'), findsOneWidget);
  });

  testWidgets('Loading, initial error and retry lead back to the inbox', (
    tester,
  ) async {
    final pending = Completer<List<AppNotification>>();
    repository.onLoad = (_) => pending.future;
    await pumpScreen(tester, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(
      find.text('No hem pogut carregar els avisos. Torna-ho a provar.'),
      findsOneWidget,
    );
    repository.onLoad = null;
    await tester.tap(find.text('Tornar-ho a provar'));
    await tester.pumpAndSettle();
    expect(unread('request'), findsOneWidget);
  });

  testWidgets(
    'A filtered empty state returns to all without changing read status',
    (tester) async {
      repository.inboxes['user-a'] = [requestNotice()];
      await pumpScreen(tester);
      await select(tester, 'reminders');
      expect(find.text('Encara no has rebut cap recordatori'), findsOneWidget);
      expect(find.text('Avui'), findsNothing);
      await tester.tap(find.text('Veure tots els avisos'));
      await tester.pumpAndSettle();
      expect(unread('request'), findsOneWidget);
      expect(repository.reads, isEmpty);
    },
  );

  testWidgets(
    'Global empty state does not suggest switching to another empty filter',
    (tester) async {
      repository.inboxes.clear();
      await pumpScreen(tester);
      expect(find.text('Encara no tens cap avís'), findsOneWidget);
      expect(find.text('Veure tots els avisos'), findsNothing);
    },
  );

  testWidgets(
    'Filters, cards, actions and empty messages tolerate large text at 320 px',
    (tester) async {
      await pumpScreen(tester, size: const Size(320, 640), textScale: 2);
      expect(tester.takeException(), isNull);
      await select(tester, 'social');
      await tester.ensureVisible(find.text('Rebutjar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await select(tester, 'recommendations');
      expect(find.text(notificationMessage(eventNotice())), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Disposing the screen during a read cannot navigate later', (
    tester,
  ) async {
    await pumpScreen(tester);
    await select(tester, 'recommendations');
    final pending = Completer<void>();
    repository.onRead = () => pending.future;
    await tester.tap(find.text(notificationMessage(eventNotice())));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pumpAndSettle();
    expect(activities, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
