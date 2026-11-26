import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Recorregut complet de l'aplicació usat tant a les proves d'integració en
/// dispositiu/emulador (`integration_test/app_smoke_test.dart`) com a la prova
/// ràpida de VM (`test/app/smoke_journey_test.dart`).
///
/// Funciona sense dependre de Firebase Auth, Google Maps ni xarxa externa.
Future<void> runAppSmokeJourney(WidgetTester tester) async {
  final auth = DemoAuthRepository();
  final localeController = LocaleController();
  await localeController.setLocale(LocaleController.defaultLocale);

  await tester.pumpWidget(
    APropApp(
      authRepository: auth,
      localeController: localeController,
      // Les dades de demostració són de setembre del 2026: fixem «ara» perquè no caduquin.
      activityClock: () => DateTime(2026, 9, 26, 9),
    ),
  );
  await tester.pumpAndSettle();

  // 1. Accés amb compte de demostració.
  expect(find.text('Inicia sessió'), findsOneWidget);
  await tester.enterText(
    find.widgetWithText(TextField, "Nom d'usuari o correu"),
    'laia@aprop.cat',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Contrasenya'),
    'Aprop2026!',
  );
  // Amaga el teclat virtual en emuladors/dispositius reals abans de prémer.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();

  final signInButton = find.text('Entra');
  await tester.ensureVisible(signInButton);
  await tester.pumpAndSettle();
  await tester.tap(signInButton);
  await tester.pumpAndSettle();

  // 2. Pantalla d'Inici (Descobreix) i cerca d'activitats.
  expect(
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
    0,
  );
  await tester.tap(find.byKey(const ValueKey('discover-search')));
  await tester.pumpAndSettle();
  expect(find.widgetWithText(AppBar, 'Cerca'), findsOneWidget);

  await tester.enterText(find.byType(TextField), 'Jazz');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
  expect(find.text('Jazz al parc'), findsOneWidget);

  // 3. Fitxa des dels resultats de la cerca i inscripció.
  await tester.tap(find.text('Jazz al parc'));
  await tester.pumpAndSettle();
  expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);

  final enrollButton = find.text('M’hi apunto');
  await tester.ensureVisible(enrollButton);
  await tester.pumpAndSettle();
  await tester.tap(enrollButton);
  await tester.pumpAndSettle();
  expect(find.text('Apuntat'), findsOneWidget);
  expect(find.widgetWithText(OutlinedButton, 'Desapunta’m'), findsOneWidget);

  await tester.tap(find.byTooltip('Tornar enrere'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Tornar enrere'));
  await tester.pumpAndSettle();

  // 4. Pestanyes Mapa, Agenda i Avisos.
  await tester.tap(find.widgetWithText(NavigationDestination, 'Mapa'));
  await tester.pumpAndSettle();
  expect(
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
    2,
  );

  await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
  await tester.pumpAndSettle();
  expect(find.widgetWithText(AppBar, 'Agenda'), findsOneWidget);

  await tester.tap(find.widgetWithText(NavigationDestination, 'Avisos'));
  await tester.pumpAndSettle();
  expect(find.widgetWithText(AppBar, 'Avisos'), findsOneWidget);

  // 5. Perfil -> Configuració -> Canvi d'idioma (ca -> en -> ca) -> Tancar sessió.
  await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
  await tester.pumpAndSettle();
  expect(find.text('Laia Soler'), findsOneWidget);

  await tester.tap(find.byTooltip('Configuració'));
  await tester.pumpAndSettle();
  expect(find.widgetWithText(AppBar, 'Configuració'), findsOneWidget);

  await tester.tap(find.text('English'));
  await tester.pumpAndSettle();
  expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
  expect(find.widgetWithText(NavigationDestination, 'Home'), findsOneWidget);

  await tester.tap(find.text('Català'));
  await tester.pumpAndSettle();
  expect(find.widgetWithText(AppBar, 'Configuració'), findsOneWidget);

  final signOutTile = find.byKey(const ValueKey('profile-sign-out'));
  await tester.scrollUntilVisible(
    signOutTile,
    200,
    scrollable: find.descendant(
      of: find.byKey(const PageStorageKey('profile-settings-scroll')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(signOutTile);
  await tester.pumpAndSettle();

  expect(find.text('Inicia sessió'), findsOneWidget);
  expect(tester.takeException(), isNull);
}
