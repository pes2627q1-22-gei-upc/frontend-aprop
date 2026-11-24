import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/models/new_activity.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_navigation.dart';

/// The plan already started, so the Agenda asks «Com va anar?» about it.
/// These tests are about the plans: leave the question for later.
Future<void> answerLater(WidgetTester tester, String activityId) async {
  await tester.tap(find.byKey(ValueKey('attendance-later-$activityId')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Plans joined in Mapa appear in Agenda day sheet and past list, and open details',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      await tester.pumpWidget(APropApp(authRepository: auth));
      await tester.pumpAndSettle();
      await openMapTab(tester);
      await tapMarker(tester, 'demo-jazz');

      final jazzCard = find.byKey(const ValueKey('demo-jazz'));
      await tester.tap(
        find.descendant(of: jazzCard, matching: find.text('M’hi apunto')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
      await tester.pumpAndSettle();
      await answerLater(tester, 'demo-jazz');

      // The demo plan (September 2026) is accessible immediately via the
      // collapsed past section as well as on its calendar day modal.
      expect(find.text('Plans passats (1)'), findsOneWidget);

      // Navigate calendar to September 2026 and tap the marked day.
      final now = DateTime.now();
      final monthOffset = (now.year - 2026) * 12 + now.month - 9;
      final button = monthOffset > 0 ? 'Mes anterior' : 'Mes següent';
      for (var i = 0; i < monthOffset.abs(); i++) {
        await tester.tap(find.byTooltip(button));
        await tester.pump();
      }
      expect(find.text('Setembre de 2026'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('agenda-day-2026-9-26')));
      await tester.pumpAndSettle();

      final sheet = find.byKey(const ValueKey('agenda-day-sheet'));
      expect(sheet, findsOneWidget);
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Jazz al parc')),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
      expect(find.text('Apuntat'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Agenda'), findsOneWidget);
      expect(find.text('Setembre de 2026'), findsOneWidget);
      expect(sheet, findsNothing);
      expect(find.text('Plans passats (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Upcoming plans appear directly below the calendar without tapping their day',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final catalogue = DemoActivityRepository();
      final upcomingDate = DateTime.now().add(const Duration(days: 10));
      final futurePlan = await catalogue.createActivity(
        NewActivity(
          title: 'Concert de tardor',
          description: 'Música en directe.',
          categories: ['agenda:categories/musica'],
          startsAt: DateTime(
            upcomingDate.year,
            upcomingDate.month,
            upcomingDate.day,
            19,
          ),
          imageAsset: 'assets/images/jazz_al_parc.jpg',
          location: const GeoPoint(latitude: 41.6176, longitude: 0.62),
          creator: const ActivityCreator(
            name: 'Laia Soler',
            userId: 'demo-laiasoler',
            isFriend: false,
          ),
        ),
      );

      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      await tester.pumpWidget(
        APropApp(authRepository: auth, activityRepository: catalogue),
      );
      await tester.pumpAndSettle();
      await openMapTab(tester);
      await tapMarker(tester, futurePlan.id);

      final card = find.byKey(ValueKey(futurePlan.id));
      await tester.tap(
        find.descendant(of: card, matching: find.text('M’hi apunto')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
      await tester.pumpAndSettle();

      // Visible directly in the upcoming list below the calendar!
      await tester.scrollUntilVisible(find.text('Concert de tardor'), 200);
      expect(find.text('Concert de tardor').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Concert de tardor'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Unenrolling from details removes the plan from Agenda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    await tester.pumpWidget(
      APropApp(
        authRepository: auth,
        activityClock: () => DateTime(2026, 9, 26, 9),
      ),
    );
    await tester.pumpAndSettle();
    await openMapTab(tester);
    await tapMarker(tester, 'demo-jazz');

    final jazzCard = find.byKey(const ValueKey('demo-jazz'));
    await tester.tap(
      find.descendant(of: jazzCard, matching: find.text('M’hi apunto')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();
    await answerLater(tester, 'demo-jazz');
    final now = DateTime.now();
    final monthOffset = (now.year - 2026) * 12 + now.month - 9;
    final button = monthOffset > 0 ? 'Mes anterior' : 'Mes següent';
    for (var i = 0; i < monthOffset.abs(); i++) {
      await tester.tap(find.byTooltip(button));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('agenda-day-2026-9-26')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('agenda-day-sheet')),
        matching: find.text('Jazz al parc'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Desapunta’m'));
    await tester.pumpAndSettle();
    expect(find.text('Vols desapuntar-te?'), findsNothing);
    expect(find.text('M’hi apunto'), findsOneWidget);
    // Sense «Desfer», la baixa s'envia passat el temps.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Agenda'), findsOneWidget);
    expect(find.text('Jazz al parc'), findsNothing);
    expect(find.text('Encara no t’has apuntat a cap pla.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('agenda-day-2026-9-26')));
    await tester.pumpAndSettle();
    expect(find.text('No tens cap pla per a aquest dia.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unenrolling from the Agenda can be undone, then removes it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    await tester.pumpWidget(APropApp(authRepository: auth));
    await tester.pumpAndSettle();
    await openMapTab(tester);
    await tapMarker(tester, 'demo-jazz');

    final jazzCard = find.byKey(const ValueKey('demo-jazz'));
    await tester.tap(
      find.descendant(of: jazzCard, matching: find.text('M’hi apunto')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();
    await answerLater(tester, 'demo-jazz');

    await tester.tap(find.byKey(const ValueKey('agenda-past-toggle')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('demo-jazz')).hitTestable(),
      200,
    );
    await tester.pumpAndSettle();

    // Same badge and button as the activity cards.
    final plan = find.byKey(const ValueKey('demo-jazz')).hitTestable();
    expect(
      find.descendant(of: plan, matching: find.text('Apuntat')),
      findsOneWidget,
    );
    final unenroll = find.descendant(
      of: plan,
      matching: find.widgetWithText(OutlinedButton, 'Desapunta’m'),
    );

    // No question: «Desfer» keeps the plan.
    await tester.tap(unenroll);
    await tester.pumpAndSettle();
    expect(find.text('Vols desapuntar-te?'), findsNothing);
    await tester.tap(find.text('Desfer'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: plan, matching: find.text('Apuntat')),
      findsOneWidget,
    );

    // Without it, the plan goes once the time is over.
    await tester.tap(unenroll);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Encara no t’has apuntat a cap pla.'), findsOneWidget);
    expect(find.text('Jazz al parc').hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
