import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/features/auth/presentation/screens/login_screen.dart';
import 'package:aprop/features/auth/presentation/screens/register_screen.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: screen));
  }

  testWidgets('El login no crida el repositori si el formulari no és vàlid', (
    tester,
  ) async {
    await pumpScreen(tester, LoginScreen(repository: repository));

    await tester.tap(find.text('Entra'));
    await tester.pumpAndSettle();

    expect(
      find.text("Introdueix el nom d'usuari o el correu."),
      findsOneWidget,
    );
    expect(find.text('Introdueix la contrasenya.'), findsOneWidget);
    expect(repository.lastCall, isNull);
  });

  testWidgets("El registre valida tots els camps abans d'enviar", (
    tester,
  ) async {
    await pumpScreen(tester, RegisterScreen(repository: repository));

    await tester.enterText(
      find.widgetWithText(TextField, 'Contrasenya'),
      'Contrasenya1!',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Repeteix la contrasenya'),
      'una altra',
    );
    final submit = find.text('Crea el compte');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Introdueix el nom.'), findsOneWidget);
    expect(find.text('Introdueix els cognoms.'), findsOneWidget);
    expect(find.text("Introdueix un nom d'usuari."), findsOneWidget);
    expect(find.text('Introdueix el correu.'), findsOneWidget);
    expect(find.text('Les contrasenyes no coincideixen.'), findsOneWidget);
    expect(repository.lastCall, isNull);
  });

  testWidgets('El botó de Google està desactivat', (tester) async {
    await pumpScreen(tester, LoginScreen(repository: repository));

    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Continua amb Google'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );

    expect(button.onPressed, isNull);
  });
}
