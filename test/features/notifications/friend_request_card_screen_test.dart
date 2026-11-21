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
  late List<String> opened;
  setUp(() {
    repository = FakeNotificationRepository(
      inboxes: {
        'user-a': [requestNotice()],
      },
    );
    opened = [];
  });
  Finder accept([String id = 'request']) =>
      find.byKey(ValueKey('notification-accept-$id'));
  Finder decline([String id = 'request']) =>
      find.byKey(ValueKey('notification-decline-$id'));
  Future<void> pumpScreen(
    WidgetTester tester, {
    bool profileAvailable = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: AppBar(title: const Text('Avisos')),
          body: NotificationsScreen(
            userId: 'user-a',
            repository: repository,
            now: () => notificationNow,
            onPersonSelected: profileAvailable ? opened.add : null,
            onActivitySelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final isRead in [false, true]) {
    testWidgets(
      'Received request renders actor/actions independently of read=$isRead; opening only reads',
      (tester) async {
        repository.inboxes['user-a'] = [requestNotice(isRead: isRead)];
        await pumpScreen(tester);
        expect(find.text('MV'), findsOneWidget);
        expect(find.text(notificationMessage(requestNotice())), findsOneWidget);
        expect(accept(), findsOneWidget);
        expect(decline(), findsOneWidget);
        expect(
          find.byKey(const ValueKey('notification-unread-request')),
          isRead ? findsNothing : findsOneWidget,
        );
        await tester.tap(find.text(notificationMessage(requestNotice())));
        await tester.pumpAndSettle();
        expect(opened, [notificationPerson.id]);
        expect(repository.responses, isEmpty);
        expect(repository.reads, isRead ? isEmpty : ['user-a/request']);
        expect(accept(), findsOneWidget);
        expect(decline(), findsOneWidget);
      },
    );
  }
  for (final accepting in [true, false]) {
    testWidgets(
      'Pending ${accepting ? 'accept' : 'decline'} disables only its request and renders the confirmed result',
      (tester) async {
        repository.inboxes['user-a'] = [
          requestNotice(),
          AppNotification.friendRequest(
            id: 'other',
            receivedAt: notificationNow.subtract(const Duration(hours: 2)),
            person: const NotificationPerson(id: 'laia', name: 'Laia Soler'),
            requestId: 'request-laia',
            isRead: true,
          ),
        ];
        final pending = Completer<FriendRequestStatus>();
        repository.onRespond = () => pending.future;
        await pumpScreen(tester);
        final social = find.byKey(const ValueKey('notification-filter-social'));
        await tester.tap(social);
        await tester.pumpAndSettle();
        await tester.tap(accepting ? accept() : decline());
        await tester.pump();
        expect(repository.responses, ['user-a/request-marc/$accepting']);
        expect(repository.reads, isEmpty);
        expect(opened, isEmpty);
        expect(find.text('Enviant la resposta'), findsOneWidget);
        expect(tester.widget<ButtonStyleButton>(accept()).onPressed, isNull);
        expect(tester.widget<ButtonStyleButton>(decline()).onPressed, isNull);
        expect(
          tester.widget<ButtonStyleButton>(accept('other')).onPressed,
          isNotNull,
        );
        pending.complete(
          accepting
              ? FriendRequestStatus.accepted
              : FriendRequestStatus.rejected,
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            accepting ? 'Sol·licitud acceptada' : 'Sol·licitud rebutjada',
          ),
          findsOneWidget,
        );
        expect(accept(), findsNothing);
        expect(decline(), findsNothing);
        expect(accept('other'), findsOneWidget);
        expect(decline('other'), findsOneWidget);
        expect(opened, isEmpty);
        expect(tester.widget<ChoiceChip>(social).selected, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'A failed response keeps both actions and a retry replaces error with confirmed feedback',
    (tester) async {
      repository.onRespond = () async => throw StateError('offline');
      await pumpScreen(tester);
      await tester.tap(accept());
      await tester.pumpAndSettle();
      expect(
        find.text('No hem pogut respondre la sol·licitud. Torna-ho a provar.'),
        findsOneWidget,
      );
      expect(accept(), findsOneWidget);
      expect(decline(), findsOneWidget);
      expect(find.text('Sol·licitud acceptada'), findsNothing);
      repository.onRespond = null;
      await tester.tap(decline());
      await tester.pumpAndSettle();
      expect(find.text('Sol·licitud rebutjada'), findsOneWidget);
      expect(find.textContaining('No hem pogut respondre'), findsNothing);
      expect(opened, isEmpty);
    },
  );
  testWidgets(
    'A request can be answered even when its profile destination is unavailable',
    (tester) async {
      await pumpScreen(tester, profileAvailable: false);
      expect(find.text('Perfil disponible properament'), findsOneWidget);
      await tester.tap(decline());
      await tester.pumpAndSettle();
      expect(repository.responses, ['user-a/request-marc/false']);
      expect(find.text('Sol·licitud rebutjada'), findsOneWidget);
      expect(opened, isEmpty);
    },
  );
  testWidgets(
    'Reading a request disables actions but does not render response-submission progress',
    (tester) async {
      final reading = Completer<void>();
      repository.onRead = () => reading.future;
      await pumpScreen(tester);
      await tester.tap(find.text(notificationMessage(requestNotice())));
      await tester.pump();
      expect(tester.widget<ButtonStyleButton>(accept()).onPressed, isNull);
      expect(tester.widget<ButtonStyleButton>(decline()).onPressed, isNull);
      expect(find.text('Enviant la resposta'), findsNothing);
      expect(repository.responses, isEmpty);
      reading.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<ButtonStyleButton>(accept()).onPressed, isNotNull);
      expect(tester.widget<ButtonStyleButton>(decline()).onPressed, isNotNull);
      expect(opened, [notificationPerson.id]);
    },
  );
}
