import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/activities/fake_enrollment_repository.dart';
import '../features/notifications/fake_notification_repository.dart';
import '../features/notifications/notification_test_data.dart';

void main() {
  testWidgets(
    'Accepted notice opens the friend profile and restores filter, scroll and read state on return',
    (tester) async {
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      final enrollments = FakeEnrollmentRepository();
      addTearDown(enrollments.dispose);
      const owner = 'demo-laiasoler';
      const julia = NotificationPerson(
        id: 'demo-person-julia',
        name: 'Júlia Riera',
      );
      final repository = FakeNotificationRepository(
        inboxes: {
          owner: [
            for (var i = 0; i < 20; i++)
              acceptedFriendNotice(
                id: 'accepted-$i',
                receivedAt: notificationNow.subtract(Duration(minutes: i)),
                person: julia,
              ),
            eventNotice(),
          ],
        },
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        APropApp(
          authRepository: auth,
          enrollmentRepository: enrollments,
          notificationRepository: repository,
        ),
      );
      await tester.pumpAndSettle();
      Finder destination(String name) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(name),
      );
      await tester.tap(destination('Avisos'));
      await tester.pumpAndSettle();
      final filter = find.byKey(const ValueKey('notification-filter-social'));
      await tester.tap(filter);
      await tester.pumpAndSettle();
      final button = find.byKey(
        const ValueKey('notification-friend-profile-accepted-10'),
      );
      await tester.scrollUntilVisible(
        button,
        300,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(button).dy;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'juliariera'), findsOneWidget);
      expect(find.text('Júlia Riera'), findsOneWidget);
      final friend = find.byKey(const ValueKey('public-profile-friend'));
      expect(
        find.descendant(of: friend, matching: find.text('Amiga/Amic')),
        findsOneWidget,
      );
      expect(tester.widget<ButtonStyleButton>(friend).onPressed, isNull);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(repository.reads, ['$owner/accepted-10']);
      expect(repository.responses, isEmpty);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(filter).selected, isTrue);
      expect(tester.getTopLeft(button).dy, closeTo(before, 1));
      expect(
        find.byKey(const ValueKey('notification-unread-accepted-10')),
        findsNothing,
      );
      expect(find.text('Acceptar'), findsNothing);
      expect(find.text('Rebutjar'), findsNothing);
      await tester.tap(destination('Inici'));
      await tester.pumpAndSettle();
      await tester.tap(destination('Avisos'));
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(filter).selected, isTrue);
      expect(tester.getTopLeft(button).dy, closeTo(before, 1));
      expect(repository.loads, [owner]);
      expect(tester.takeException(), isNull);
    },
  );
}
