import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Plans joined in Inici appear in Agenda and open details', (
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

    final jazzCard = find.byKey(const ValueKey('demo-jazz'));
    await tester.tap(
      find.descendant(of: jazzCard, matching: find.text('M’hi apunto')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();

    // The agenda opens on the real current month; the demo plan is in
    // September 2026.
    final now = DateTime.now();
    final monthOffset = (now.year - 2026) * 12 + now.month - 9;
    final button = monthOffset > 0 ? 'Mes anterior' : 'Mes següent';
    for (var i = 0; i < monthOffset.abs(); i++) {
      await tester.tap(find.byTooltip(button));
      await tester.pump();
    }
    expect(find.text('Setembre de 2026'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('agenda-day-2026-9-26')));
    await tester.pump();
    await tester.tap(find.text('Jazz al parc'));
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
    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unenrolling from details removes the plan from Agenda', (
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

    final jazzCard = find.byKey(const ValueKey('demo-jazz'));
    await tester.tap(
      find.descendant(of: jazzCard, matching: find.text('M’hi apunto')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final monthOffset = (now.year - 2026) * 12 + now.month - 9;
    final button = monthOffset > 0 ? 'Mes anterior' : 'Mes següent';
    for (var i = 0; i < monthOffset.abs(); i++) {
      await tester.tap(find.byTooltip(button));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('agenda-day-2026-9-26')));
    await tester.pump();
    await tester.tap(find.text('Jazz al parc'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Desapunta’m'));
    await tester.pumpAndSettle();
    expect(find.text('Vols desapuntar-te?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Desapunta’m'));
    await tester.pumpAndSettle();
    expect(find.text('M’hi apunto'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Agenda'), findsOneWidget);
    expect(find.text('Jazz al parc'), findsNothing);
    expect(find.text('No tens cap pla per a aquest dia.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unenrolling from the Agenda asks first, then removes the plan', (
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

    final jazzCard = find.byKey(const ValueKey('demo-jazz'));
    await tester.tap(
      find.descendant(of: jazzCard, matching: find.text('M’hi apunto')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final monthOffset = (now.year - 2026) * 12 + now.month - 9;
    final button = monthOffset > 0 ? 'Mes anterior' : 'Mes següent';
    for (var i = 0; i < monthOffset.abs(); i++) {
      await tester.tap(find.byTooltip(button));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('agenda-day-2026-9-26')));
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

    // Cancelling keeps the plan.
    await tester.tap(unenroll);
    await tester.pumpAndSettle();
    expect(find.text('Vols desapuntar-te?'), findsOneWidget);
    await tester.tap(find.text('Mantén el pla'));
    await tester.pumpAndSettle();
    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);

    await tester.tap(unenroll);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Desapunta’m'));
    await tester.pumpAndSettle();

    expect(find.text('No tens cap pla per a aquest dia.'), findsOneWidget);
    expect(find.text('Jazz al parc').hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
