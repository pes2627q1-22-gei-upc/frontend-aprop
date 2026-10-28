import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/features/auth/models/auth_failure.dart';
import 'package:aprop/features/auth/presentation/view_models/auth_failure_message.dart';
import 'package:aprop/features/auth/presentation/view_models/login_view_model.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late LoginViewModel viewModel;

  setUp(() {
    repository = FakeAuthRepository();
    viewModel = LoginViewModel(repository: repository);
  });

  tearDown(() => viewModel.dispose());

  test("Inicia sessió sense espais a l'usuari o correu", () async {
    final success = await viewModel.signIn(
      usernameOrEmail: '  laia@aprop.cat ',
      password: 'Aprop2026!',
    );

    expect(success, isTrue);
    expect(repository.lastCall, {
      'usernameOrEmail': 'laia@aprop.cat',
      'password': 'Aprop2026!',
    });
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.isLoading, isFalse);
  });

  test('Indica que està carregant mentre espera el repositori', () async {
    repository.pending = Completer<void>();

    final result = viewModel.signIn(
      usernameOrEmail: 'a@b.cat',
      password: '12345678',
    );
    expect(viewModel.isLoading, isTrue);

    repository.pending!.complete();
    await result;
    expect(viewModel.isLoading, isFalse);
  });

  test('Mostra el missatge de credencials incorrectes', () async {
    repository.error = AuthFailure.invalidCredentials;

    final success = await viewModel.signIn(
      usernameOrEmail: 'a@b.cat',
      password: 'x',
    );

    expect(success, isFalse);
    expect(viewModel.errorMessage, AuthFailure.invalidCredentials.message);
  });

  test('Mostra un missatge genèric si falla inesperadament', () async {
    repository.error = Exception('error intern');

    final success = await viewModel.signIn(
      usernameOrEmail: 'a@b.cat',
      password: 'x',
    );

    expect(success, isFalse);
    expect(viewModel.errorMessage, unexpectedAuthErrorMessage);
  });

  test("Esborra l'error anterior en tornar-ho a provar", () async {
    repository.error = AuthFailure.network;
    await viewModel.signIn(usernameOrEmail: 'a@b.cat', password: 'x');

    repository.error = null;
    await viewModel.signIn(usernameOrEmail: 'a@b.cat', password: 'x');

    expect(viewModel.errorMessage, isNull);
  });

  test('No crida el repositori si hi ha camps invàlids', () async {
    final success = await viewModel.signIn(usernameOrEmail: ' ', password: '');

    expect(success, isFalse);
    expect(repository.lastCall, isNull);
    expect(
      viewModel.fieldError(LoginField.usernameOrEmail),
      "Introdueix el nom d'usuari o el correu.",
    );
    expect(
      viewModel.fieldError(LoginField.password),
      'Introdueix la contrasenya.',
    );
  });

  test(
    "En modificar un camp se n'esborra l'error i el missatge general",
    () async {
      await viewModel.signIn(usernameOrEmail: ' ', password: '');
      viewModel.onFieldChanged(LoginField.usernameOrEmail);

      expect(viewModel.fieldError(LoginField.usernameOrEmail), isNull);
      expect(viewModel.fieldError(LoginField.password), isNotNull);

      repository.error = AuthFailure.invalidCredentials;
      await viewModel.signIn(
        usernameOrEmail: 'laia@aprop.cat',
        password: 'incorrecta',
      );
      expect(viewModel.errorMessage, isNotNull);

      var notified = false;
      viewModel.addListener(() => notified = true);
      viewModel.onFieldChanged(LoginField.password);

      expect(viewModel.errorMessage, isNull);
      expect(notified, isTrue);
    },
  );

  test('Entra amb Google', () async {
    final result = viewModel.signInWithGoogle();
    expect(viewModel.isGoogleLoading, isTrue);

    expect(await result, isTrue);
    expect(repository.googleSignIns, 1);
    expect(viewModel.isGoogleLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
  });

  test('Si es tanca el selector de Google no mostra cap error', () async {
    repository.googleAccountChosen = false;

    expect(await viewModel.signInWithGoogle(), isFalse);
    expect(viewModel.errorMessage, isNull);
  });

  test("Mostra l'error si no es pot entrar amb Google", () async {
    repository.error = AuthFailure.network;

    expect(await viewModel.signInWithGoogle(), isFalse);
    expect(viewModel.errorMessage, AuthFailure.network.message);
  });

  test("No entra amb Google mentre s'envia el formulari", () async {
    repository.pending = Completer<void>();
    final signIn = viewModel.signIn(
      usernameOrEmail: 'a@b.cat',
      password: '12345678',
    );

    expect(await viewModel.signInWithGoogle(), isFalse);
    expect(repository.googleSignIns, 0);

    repository.pending!.complete();
    await signIn;
  });
}
