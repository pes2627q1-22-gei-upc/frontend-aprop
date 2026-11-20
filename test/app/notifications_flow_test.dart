import 'dart:async';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/presentation/formatters/notification_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/activities/fake_enrollment_repository.dart';
import '../features/notifications/fake_notification_repository.dart';
import '../features/notifications/notification_test_data.dart';
import 'app_navigation.dart';

void main() {
  late DemoAuthRepository auth;
  late FakeNotificationRepository notices;
  late FakeEnrollmentRepository enrollments;
  const user = 'demo-laiasoler';
  setUp(() async {
    auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    notices = FakeNotificationRepository(
      inboxes: {
        user: [requestNotice(), eventNotice()],
      },
    );
    enrollments = FakeEnrollmentRepository();
  });
  tearDown(() => enrollments.dispose());

  Finder destination(String name) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(name),
  );
  Finder filter(String name) =>
      find.byKey(ValueKey('notification-filter-$name'));
  Future<void> selectFilter(WidgetTester tester, String name) async {
    await tester.ensureVisible(filter(name));
    await tester.tap(filter(name));
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(WidgetTester tester, {bool useDemo = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      APropApp(
        authRepository: auth,
        enrollmentRepository: enrollments,
        notificationRepository: useDemo ? null : notices,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(destination('Avisos'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'A recommendation opens the shared detail without enrolling and retains its filter',
    (tester) async {
      await pumpApp(tester);
      expect(find.widgetWithText(AppBar, 'Avisos'), findsOneWidget);
      expect(find.text('Assistent'), findsNothing);
      await selectFilter(tester, 'recommendations');
      await tester.tap(find.text(notificationMessage(eventNotice())));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(find.text('M’hi apunto'), findsOneWidget);
      expect(enrollments.enrolledRequests, isEmpty);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ChoiceChip>(filter('recommendations')).selected,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('notification-unread-recommendation')),
        findsNothing,
      );
      expect(notices.reads, ['$user/recommendation']);
    },
  );

  testWidgets(
    'Returning from details and switching sections preserve the scroll position',
    (tester) async {
      notices.inboxes[user] = [
        for (var i = 0; i < 30; i++)
          eventNotice(
            id: 'recommendation-$i',
            receivedAt: DateTime(2026, 9, 26, 18, i),
          ),
      ];
      await pumpApp(tester);
      await selectFilter(tester, 'recommendations');
      final card = find.byKey(const ValueKey('notification-recommendation-10'));
      await tester.scrollUntilVisible(
        card,
        300,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(card).dy;
      await tester.tap(
        find.descendant(
          of: card,
          matching: find.text(notificationMessage(eventNotice())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(card).dy, closeTo(before, 1));
      await tester.tap(destination('Mapa'));
      await tester.pumpAndSettle();
      await tester.tap(destination('Avisos'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(card).dy, closeTo(before, 1));
    },
  );

  testWidgets(
    'A read completing after switching tabs does not open an unrelated route',
    (tester) async {
      await pumpApp(tester);
      await selectFilter(tester, 'recommendations');
      final pending = Completer<void>();
      notices.onRead = () => pending.future;
      await tester.tap(find.text(notificationMessage(eventNotice())));
      await tester.pump();
      await tester.tap(destination('Mapa'));
      await tester.pumpAndSettle();
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Activitat'), findsNothing);
      expect(markerIds(tester), isNotEmpty);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2, // Mapa
      );
    },
  );

  testWidgets(
    'A response arriving after an account change cannot alter the new inbox',
    (tester) async {
      await pumpApp(tester);
      await selectFilter(tester, 'social');
      final pending = Completer<FriendRequestStatus>();
      notices.onRespond = () => pending.future;
      await tester.tap(find.text('Acceptar'));
      await tester.pump();
      await auth.signOut();
      await tester.pumpAndSettle();
      await auth.register(
        firstName: 'Pol',
        lastName: 'Vidal',
        username: 'pol',
        email: 'pol@example.test',
        password: 'Password1!',
      );
      await auth.checkEmailVerified();
      await tester.pumpAndSettle();
      await tester.tap(destination('Avisos'));
      await tester.pumpAndSettle();
      pending.complete(FriendRequestStatus.accepted);
      await tester.pumpAndSettle();
      expect(find.text('Encara no tens cap avís'), findsOneWidget);
      expect(find.text('Sol·licitud acceptada'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Default demo repository keeps a response through sign-out and sign-in',
    (tester) async {
      await pumpApp(tester, useDemo: true);
      await selectFilter(tester, 'social');
      await tester.ensureVisible(find.text('Acceptar'));
      await tester.tap(find.text('Acceptar'));
      await tester.pumpAndSettle();
      expect(find.text('Sol·licitud acceptada'), findsOneWidget);
      await auth.signOut();
      await tester.pumpAndSettle();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      await tester.pumpAndSettle();
      await tester.tap(destination('Avisos'));
      await tester.pumpAndSettle();
      await selectFilter(tester, 'social');
      await tester.ensureVisible(find.text('Sol·licitud acceptada'));
      expect(find.text('Acceptar'), findsNothing);
      expect(find.text('Sol·licitud acceptada'), findsOneWidget);
    },
  );
}
