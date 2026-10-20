import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<APropApp> signedInApp() async {
    final auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    return APropApp(authRepository: auth);
  }

  testWidgets(
    'Assistent flow preserves conversation after opening details and syncs enrollment',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await signedInApp());
      await tester.pumpAndSettle();

      // Open Assistant from Inici header
      await tester.tap(find.widgetWithText(FilledButton, 'Assistent'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Assistent'), findsOneWidget);

      // Ask for theatre in Tarragona on September 27
      await tester.enterText(
        find.byKey(const ValueKey('assistant-query-field')),
        'Teatre a Tarragona el 27 de setembre',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(find.text('Tipus: Teatre'), findsOneWidget);
      expect(find.text('Municipi: Tarragona'), findsOneWidget);
      expect(find.text('Dates: 27 set. 2026'), findsOneWidget);
      expect(find.text('Teatre sota les estrelles'), findsOneWidget);

      // Scroll to the recommended card and enroll directly from the assistant
      await tester.ensureVisible(find.text('M’hi apunto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('M’hi apunto'));
      await tester.pumpAndSettle();
      expect(find.text('Apuntat'), findsOneWidget);

      // Open the recommended activity details
      await tester.ensureVisible(find.text('Teatre sota les estrelles'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teatre sota les estrelles'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
      expect(find.text('Apuntat'), findsOneWidget);

      // Return from details: conversation and recommendation are preserved
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Assistent'), findsOneWidget);
      expect(find.text('Teatre sota les estrelles'), findsOneWidget);
      expect(find.text('Apuntat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
