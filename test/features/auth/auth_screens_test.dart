import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/features/auth/models/auth_failure.dart';
import 'package:aprop/features/auth/presentation/view_models/auth_failure_message.dart';
import 'package:aprop/features/auth/presentation/screens/choose_username_screen.dart';
import 'package:aprop/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:aprop/features/auth/presentation/view_models/forgot_password_view_model.dart';
import 'package:aprop/features/auth/presentation/screens/login_screen.dart';
import 'package:aprop/features/auth/presentation/screens/register_screen.dart';
import 'package:aprop/features/auth/presentation/screens/verify_email_screen.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
    );
  }

  testWidgets("Amb la lletra gran les ajudes del registre no es tallen", (
    tester,
  ) async {
    await pumpScreen(
      tester,
      RegisterScreen(repository: repository),
      textScale: 2,
    );

    for (final helper in [
      'Minúscules, números, punt o guió baix (3-20).',
      'Mínim 8 caràcters, amb majúscula, minúscula, número i caràcter '
          'especial.',
    ]) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(helper));
      expect(paragraph.didExceedMaxLines, isFalse, reason: helper);
    }
  });

  testWidgets('El lector de pantalla anuncia els errors generals', (
    tester,
  ) async {
    repository.error = AuthFailure.invalidCredentials;
    await pumpScreen(tester, LoginScreen(repository: repository));

    await tester.enterText(
      find.widgetWithText(TextField, "Nom d'usuari o correu"),
      'laia@aprop.cat',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Contrasenya'),
      'incorrecta',
    );
    await tester.tap(find.text('Entra'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text(AuthFailure.invalidCredentials.message)),
      isSemantics(isLiveRegion: true),
    );
  });

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

  testWidgets('«Següent» a la contrasenya porta a repetir-la', (tester) async {
    await pumpScreen(tester, RegisterScreen(repository: repository));

    bool hasFocus(String label) => tester
        .widget<EditableText>(
          find.descendant(
            of: find.widgetWithText(TextField, label),
            matching: find.byType(EditableText),
          ),
        )
        .focusNode
        .hasFocus;

    await tester.tap(find.widgetWithText(TextField, 'Contrasenya'));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(hasFocus('Repeteix la contrasenya'), isTrue);
  });

  testWidgets('Reenviar el correu espera 60 segons cada vegada', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      VerifyEmailScreen(repository: repository, email: 'pol@aprop.cat'),
    );

    ButtonStyleButton resendButton() => tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.textContaining('Torna a enviar el correu'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );

    expect(find.text('Torna a enviar el correu (60 s)'), findsOneWidget);
    expect(resendButton().onPressed, isNull);

    await tester.pump(const Duration(seconds: 59));
    expect(find.text('Torna a enviar el correu (1 s)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Torna a enviar el correu'), findsOneWidget);

    await tester.tap(find.text('Torna a enviar el correu'));
    await tester.pump();

    expect(repository.verificationEmailsSent, 1);
    expect(find.text("T'hem tornat a enviar el correu."), findsOneWidget);
    expect(find.text('Torna a enviar el correu (60 s)'), findsOneWidget);
  });

  testWidgets("Mentre s'entra amb Google no es pot enviar el formulari", (
    tester,
  ) async {
    repository.pending = Completer<void>();
    await pumpScreen(tester, LoginScreen(repository: repository));

    ButtonStyleButton buttonWith(String text) =>
        tester.widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text(text),
            matching: find.bySubtype<ButtonStyleButton>(),
          ),
        );

    await tester.tap(find.text('Continua amb Google'));
    await tester.pump();

    expect(repository.googleSignIns, 1);
    expect(buttonWith('Entra').onPressed, isNull);
    expect(buttonWith('Continua amb Google').onPressed, isNull);
    // Només carrega Google: el botó «Entra» no mostra l'indicador.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.pending!.complete();
    await tester.pumpAndSettle();

    expect(buttonWith('Entra').onPressed, isNotNull);
    expect(buttonWith('Continua amb Google').onPressed, isNotNull);
  });

  testWidgets("Amb la lletra gran l'ajuda del nom d'usuari no es talla", (
    tester,
  ) async {
    await pumpScreen(
      tester,
      ChooseUsernameScreen(repository: repository, firstName: 'Jordi'),
      textScale: 2,
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Minúscules, números, punt o guió baix (3-20).'),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  testWidgets('Saluda sense nom si el compte no en té', (tester) async {
    await pumpScreen(
      tester,
      ChooseUsernameScreen(repository: repository, firstName: ' '),
    );

    expect(find.textContaining('Hola!'), findsOneWidget);
    expect(find.textContaining('Hola, '), findsNothing);
  });

  testWidgets("Explica que el nom triat en registrar-se ja era d'algú altre", (
    tester,
  ) async {
    await pumpScreen(
      tester,
      ChooseUsernameScreen(
        repository: repository,
        firstName: 'Pol',
        rejectedUsername: 'polvidal',
      ),
    );

    expect(
      find.text(
        "El nom «polvidal» ja és d'una altra persona. Tria'n un altre.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('Sense nom rebutjat no mostra cap avís', (tester) async {
    await pumpScreen(
      tester,
      ChooseUsernameScreen(repository: repository, firstName: 'Pol'),
    );

    expect(find.textContaining("ja és d'una altra persona"), findsNothing);
  });

  group('Recuperar la contrasenya', () {
    testWidgets('El login hi porta amb el correu que ja hi havia escrit', (
      tester,
    ) async {
      await pumpScreen(tester, LoginScreen(repository: repository));
      await tester.enterText(
        find.widgetWithText(TextField, "Nom d'usuari o correu"),
        ' laia@aprop.cat ',
      );

      await tester.tap(find.text('Has oblidat la contrasenya?'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      final email = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Correu'),
      );
      expect(email.controller!.text, 'laia@aprop.cat');

      // «Torna a l'inici de sessió» hi torna.
      await tester.tap(find.text("Torna a l'inici de sessió"));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsNothing);
      expect(find.text('Inicia sessió'), findsOneWidget);
    });

    testWidgets("Un nom d'usuari no s'hi copia com a correu", (tester) async {
      await pumpScreen(tester, LoginScreen(repository: repository));
      await tester.enterText(
        find.widgetWithText(TextField, "Nom d'usuari o correu"),
        'laiasoler',
      );

      await tester.tap(find.text('Has oblidat la contrasenya?'));
      await tester.pumpAndSettle();

      final email = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Correu'),
      );
      expect(email.controller!.text, isEmpty);
    });

    testWidgets('Envia l\'enllaç i espera 60 segons per tornar-lo a enviar', (
      tester,
    ) async {
      await pumpScreen(tester, ForgotPasswordScreen(repository: repository));

      await tester.tap(find.text("Envia l'enllaç"));
      await tester.pump();
      expect(find.text('Introdueix el correu.'), findsOneWidget);
      expect(repository.passwordResetEmails, isEmpty);

      await tester.enterText(
        find.widgetWithText(TextField, 'Correu'),
        'laia@aprop.cat',
      );
      await tester.tap(find.text("Envia l'enllaç"));
      await tester.pump();

      expect(repository.passwordResetEmails, ['laia@aprop.cat']);
      expect(find.text(passwordResetSentMessage), findsOneWidget);
      expect(find.text("Torna a enviar l'enllaç (60 s)"), findsOneWidget);

      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text("Torna a enviar l'enllaç"));
      await tester.pump();
      expect(repository.passwordResetEmails, hasLength(2));
    });

    testWidgets('Amb la lletra gran la pantalla es pot fer servir', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        ForgotPasswordScreen(
          repository: repository,
          initialEmail: 'laia@aprop.cat',
        ),
        textScale: 2,
      );

      await tester.ensureVisible(find.text("Envia l'enllaç"));
      await tester.tap(find.text("Envia l'enllaç"));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(repository.passwordResetEmails, ['laia@aprop.cat']);
    });
  });
}
