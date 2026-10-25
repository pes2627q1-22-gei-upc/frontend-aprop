import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';

void main() {
  late DemoAuthRepository repository;

  setUp(() => repository = DemoAuthRepository());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(APropApp(authRepository: repository));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String label, String text) {
    return tester.enterText(find.widgetWithText(TextField, label), text);
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.text(label);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('Sense sessió mostra el login i hi entra', (tester) async {
    await pumpApp(tester);

    expect(find.text('Inicia sessió'), findsOneWidget);
    expect(find.text('Jazz al parc'), findsNothing);

    await fill(tester, "Nom d'usuari o correu", 'laia@aprop.cat');
    await fill(tester, 'Contrasenya', 'Aprop2026!');
    await tapButton(tester, 'Entra');

    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("També s'hi pot entrar amb el nom d'usuari", (tester) async {
    await pumpApp(tester);

    await fill(tester, "Nom d'usuari o correu", 'laiasoler');
    await fill(tester, 'Contrasenya', 'Aprop2026!');
    await tapButton(tester, 'Entra');

    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);
  });

  testWidgets('Avisa si les credencials no són correctes', (tester) async {
    await pumpApp(tester);

    await fill(tester, "Nom d'usuari o correu", 'laia@aprop.cat');
    await fill(tester, 'Contrasenya', 'incorrecta');
    await tapButton(tester, 'Entra');

    expect(
      find.text("L'usuari o la contrasenya no són correctes."),
      findsOneWidget,
    );
    expect(find.text('Inicia sessió'), findsOneWidget);

    await fill(tester, 'Contrasenya', 'Aprop2025!');
    await tester.pump();

    expect(
      find.text("L'usuari o la contrasenya no són correctes."),
      findsNothing,
    );
  });

  testWidgets("L'error d'un camp desapareix en modificar-lo", (tester) async {
    await pumpApp(tester);
    await tapButton(tester, 'Entra');

    expect(
      find.text("Introdueix el nom d'usuari o el correu."),
      findsOneWidget,
    );
    expect(find.text('Introdueix la contrasenya.'), findsOneWidget);

    await fill(tester, "Nom d'usuari o correu", 'l');
    await tester.pump();

    expect(find.text("Introdueix el nom d'usuari o el correu."), findsNothing);
    expect(find.text('Introdueix la contrasenya.'), findsOneWidget);
  });

  Future<void> registerPol(WidgetTester tester) async {
    await tapButton(tester, 'Crea un compte');

    expect(find.widgetWithText(AppBar, 'Crea un compte'), findsOneWidget);

    await fill(tester, 'Nom', 'Pol');
    await fill(tester, 'Cognoms', 'Vidal');
    await fill(tester, "Nom d'usuari", 'polvidal');
    await fill(tester, 'Correu electrònic', 'pol@aprop.cat');
    await fill(tester, 'Contrasenya', 'Contrasenya1!');
    await fill(tester, 'Repeteix la contrasenya', 'Contrasenya1!');
    await tapButton(tester, 'Crea el compte');
  }

  testWidgets("Registra un compte nou, el verifica i entra a l'app", (
    tester,
  ) async {
    await pumpApp(tester);
    await registerPol(tester);

    expect(find.text('Crea un compte'), findsNothing);
    expect(find.text('Verifica el teu correu'), findsOneWidget);
    expect(find.textContaining('pol@aprop.cat'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tapButton(tester, "Ja l'he verificat");

    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Pol Vidal'), findsOneWidget);
    expect(find.text('polvidal'), findsOneWidget);
  });

  testWidgets("Es pot verificar enganxant l'enllaç del correu", (tester) async {
    await pumpApp(tester);
    await registerPol(tester);

    await fill(tester, 'Enllaç del correu', 'no és cap enllaç');
    await tapButton(tester, "Verifica amb l'enllaç");
    expect(find.textContaining("Aquest enllaç no és vàlid"), findsOneWidget);

    await fill(
      tester,
      'Enllaç del correu',
      'https://aprop-919ec.firebaseapp.com/__/auth/action?mode=verifyEmail'
          '&oobCode=codi-de-prova',
    );
    await tapButton(tester, "Verifica amb l'enllaç");

    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);
  });

  testWidgets("Un compte sense verificar no pot entrar a l'app", (
    tester,
  ) async {
    await pumpApp(tester);
    await registerPol(tester);
    await tapButton(tester, 'Tanca la sessió');

    expect(find.text('Inicia sessió'), findsOneWidget);

    await fill(tester, "Nom d'usuari o correu", 'polvidal');
    await fill(tester, 'Contrasenya', 'Contrasenya1!');
    await tapButton(tester, 'Entra');

    expect(find.text('Verifica el teu correu'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets("El primer accés amb Google demana el nom d'usuari", (
    tester,
  ) async {
    await pumpApp(tester);
    await tapButton(tester, 'Continua amb Google');

    expect(find.text("Tria el teu nom d'usuari"), findsOneWidget);
    expect(find.textContaining('Hola, Jordi!'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await fill(tester, "Nom d'usuari", 'laiasoler');
    await tapButton(tester, 'Continua');

    expect(
      find.text("Aquest nom d'usuari ja està agafat. Prova'n un altre."),
      findsOneWidget,
    );

    await fill(tester, "Nom d'usuari", 'jordipuig');
    await tapButton(tester, 'Continua');

    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Jordi Puig'), findsOneWidget);
    expect(find.text('jordipuig'), findsOneWidget);
  });

  testWidgets('Google des del registre tanca el formulari', (tester) async {
    await pumpApp(tester);
    await tapButton(tester, 'Crea un compte');
    await tapButton(tester, 'Continua amb Google');

    expect(find.widgetWithText(AppBar, 'Crea un compte'), findsNothing);
    expect(find.text("Tria el teu nom d'usuari"), findsOneWidget);
  });

  testWidgets("Es pot sortir sense triar el nom d'usuari", (tester) async {
    await pumpApp(tester);
    await tapButton(tester, 'Continua amb Google');
    await tapButton(tester, 'Tanca la sessió');

    expect(find.text('Inicia sessió'), findsOneWidget);
  });

  testWidgets('Tanca la sessió des de la configuració de Perfil', (
    tester,
  ) async {
    await repository.signIn(
      usernameOrEmail: 'laia@aprop.cat',
      password: 'Aprop2026!',
    );
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Laia Soler'), findsOneWidget);

    await tester.tap(find.byTooltip('Configuració'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-sign-out')),
      300,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('profile-settings-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('profile-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-sign-out')));
    await tester.pumpAndSettle();

    expect(find.text('Inicia sessió'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
