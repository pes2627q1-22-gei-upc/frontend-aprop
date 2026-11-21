import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/push/models/push_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/activities/fake_enrollment_repository.dart';
import '../features/push/fake_push.dart';

/// #265: push notifications in the app.
void main() {
  late FakePushMessaging messaging;
  late FakePushDevices devices;
  late FakeEnrollmentRepository enrollments;
  late DemoAuthRepository auth;

  setUp(() async {
    messaging = FakePushMessaging();
    devices = FakePushDevices();
    enrollments = FakeEnrollmentRepository();
    auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
  });
  tearDown(() async {
    await enrollments.dispose();
    await messaging.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      APropApp(
        authRepository: auth,
        enrollmentRepository: enrollments,
        pushMessaging: messaging,
        pushDeviceRepository: devices,
      ),
    );
    await tester.pumpAndSettle();
  }

  NavigationBar navigationBar(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar));

  testWidgets('En entrar, el mòbil es registra per rebre pushes', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(devices.registered, ['android:device-1']);
  });

  testWidgets('Amb l’app oberta, el push surt a baix i «Veure» obre Avisos', (
    tester,
  ) async {
    await pumpApp(tester);

    messaging.receive(
      const PushMessage(title: 'Avís', body: 'Tens una nova sol·licitud.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tens una nova sol·licitud.'), findsOneWidget);

    await tester.tap(find.text('Veure'));
    await tester.pumpAndSettle();
    expect(navigationBar(tester).selectedIndex, 3);
  });

  testWidgets('Tocar el push d’una activitat obre la seva fitxa a Avisos', (
    tester,
  ) async {
    await pumpApp(tester);

    messaging.open(
      const PushMessage(type: 'Recordatori', activityId: 'demo-jazz'),
    );
    await tester.pumpAndSettle();

    expect(navigationBar(tester).selectedIndex, 3);
    expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
    expect(find.text('Jazz al parc'), findsWidgets);
  });

  testWidgets('En tancar la sessió, el mòbil deixa de rebre pushes', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configuració'));
    await tester.pumpAndSettle();
    final signOut = find.byKey(const ValueKey('profile-sign-out'));
    await tester.scrollUntilVisible(
      signOut,
      300,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('profile-settings-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(signOut);
    await tester.pumpAndSettle();

    expect(devices.unregistered, ['device-1']);
    expect(find.text('Inicia sessió'), findsOneWidget);
  });
}
