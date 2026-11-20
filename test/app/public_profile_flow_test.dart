import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/activities/fake_enrollment_repository.dart';
import 'app_navigation.dart';

/// #277: another person's profile from an activity's creator and a notice.
void main() {
  late DemoAuthRepository auth;
  late FakeEnrollmentRepository enrollments;

  setUp(() => enrollments = FakeEnrollmentRepository());
  tearDown(() => enrollments.dispose());

  Future<void> pumpApp(WidgetTester tester, {required bool asLaia}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    auth = DemoAuthRepository();
    if (asLaia) {
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    } else {
      await auth.register(
        firstName: 'Pol',
        lastName: 'Vidal',
        username: 'polvidal',
        email: 'pol@example.test',
        password: 'Password1!',
      );
      await auth.checkEmailVerified();
    }
    await tester.pumpWidget(
      APropApp(authRepository: auth, enrollmentRepository: enrollments),
    );
    await tester.pumpAndSettle();
  }

  /// Opens «Teatre sota les estrelles», created by Laia, and its creator.
  Future<void> openTheatreCreator(WidgetTester tester) async {
    // Since #274 the Mapa tab only has the map: open its marker's card.
    await openMapTab(tester);
    await tapMarker(tester, 'demo-theatre');
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('demo-theatre')),
        matching: find.text('Teatre sota les estrelles'),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('activity-creator-profile'));
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('El creador d’una activitat obre el seu perfil amb els plans', (
    tester,
  ) async {
    await pumpApp(tester, asLaia: false);
    await openTheatreCreator(tester);

    expect(find.widgetWithText(AppBar, 'laiasoler'), findsOneWidget);
    expect(find.text('Laia Soler'), findsOneWidget);
    expect(find.text('Compartir perfil'), findsOneWidget);
    expect(find.text('Editar perfil'), findsNothing);
    // Laia is a friend who shares her plans: «Plans fets» opens first.
    expect(
      find.byKey(const ValueKey('public-profile-activity-demo-jazz')),
      findsOneWidget,
    );

    await tester.tap(find.text('Creats'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('public-profile-activity-demo-theatre')),
      findsOneWidget,
    );

    // Back to the activity, still in the Mapa tab.
    await tester.tap(find.byTooltip('Tornar enrere'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El creador és qui mira: obre el seu Perfil', (tester) async {
    await pumpApp(tester, asLaia: true);
    await openTheatreCreator(tester);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 4);
    expect(find.text('Editar perfil'), findsOneWidget);
  });

  testWidgets(
    'Un avís d’una persona obre el seu perfil; els plans són privats',
    (tester) async {
      await pumpApp(tester, asLaia: true);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Avisos'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('notification-filter-social')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.textContaining('Marc Vidal', findRichText: true).first,
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'marcvidal'), findsOneWidget);
      // Private plans: the profile opens on «Creats».
      expect(
        find.text('Marc Vidal encara no ha creat cap activitat.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Plans fets'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Els plans de Marc Vidal només els poden veure els seus amics.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
