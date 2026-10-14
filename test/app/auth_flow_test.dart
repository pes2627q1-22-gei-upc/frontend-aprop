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

  testWidgets("Registra un compte nou i entra a l'app", (tester) async {
    await pumpApp(tester);
    await tapButton(tester, "Registra't");

    expect(find.widgetWithText(AppBar, 'Crea un compte'), findsOneWidget);

    await fill(tester, 'Nom', 'Pol');
    await fill(tester, 'Cognoms', 'Vidal');
    await fill(tester, "Nom d'usuari", 'polvidal');
    await fill(tester, 'Correu electrònic', 'pol@aprop.cat');
    await fill(tester, 'Contrasenya', 'Contrasenya1!');
    await fill(tester, 'Repeteix la contrasenya', 'Contrasenya1!');
    await tapButton(tester, 'Crea el compte');

    expect(find.text('Crea un compte'), findsNothing);
    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Pol Vidal'), findsOneWidget);
    expect(find.text('@polvidal'), findsOneWidget);
  });

  testWidgets('Tanca la sessió des de Perfil', (tester) async {
    await repository.signIn(
      usernameOrEmail: 'laia@aprop.cat',
      password: 'Aprop2026!',
    );
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Laia Soler'), findsOneWidget);

    await tapButton(tester, 'Tanca la sessió');

    expect(find.text('Inicia sessió'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
