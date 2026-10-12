import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/features/auth/models/auth_failure.dart';
import 'package:aprop/features/auth/presentation/view_models/auth_failure_message.dart';
import 'package:aprop/features/auth/presentation/view_models/register_view_model.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late RegisterViewModel viewModel;

  setUp(() {
    repository = FakeAuthRepository();
    viewModel = RegisterViewModel(repository: repository);
  });

  tearDown(() => viewModel.dispose());

  Future<bool> registerPol() {
    return viewModel.register(
      firstName: ' Pol ',
      lastName: ' Vidal Puig ',
      username: ' polvidal ',
      email: ' pol@aprop.cat ',
      password: ' Contrasenya1! ',
      passwordConfirmation: ' Contrasenya1! ',
    );
  }

  test('No crida el repositori si hi ha camps invàlids', () async {
    final success = await viewModel.register(
      firstName: 'Pol',
      lastName: '',
      username: 'Pol Vidal',
      email: 'pol@aprop.cat',
      password: 'Contrasenya1!',
      passwordConfirmation: 'una altra',
    );

    expect(success, isFalse);
    expect(repository.lastCall, isNull);
    expect(viewModel.fieldError(RegisterField.firstName), isNull);
    expect(viewModel.fieldError(RegisterField.lastName), isNotNull);
    expect(viewModel.fieldError(RegisterField.username), isNotNull);
    expect(viewModel.fieldError(RegisterField.email), isNull);
    expect(
      viewModel.fieldError(RegisterField.passwordConfirmation),
      'Les contrasenyes no coincideixen.',
    );
  });

  test("En modificar un camp només se n'esborra el seu error", () async {
    await viewModel.register(
      firstName: '',
      lastName: '',
      username: 'polvidal',
      email: 'pol@aprop.cat',
      password: 'Contrasenya1!',
      passwordConfirmation: 'Contrasenya1!',
    );

    viewModel.onFieldChanged(RegisterField.firstName);

    expect(viewModel.fieldError(RegisterField.firstName), isNull);
    expect(viewModel.fieldError(RegisterField.lastName), isNotNull);
  });

  test('Envia les dades sense espais, excepte la contrasenya', () async {
    final success = await registerPol();

    expect(success, isTrue);
    expect(repository.lastCall, {
      'firstName': 'Pol',
      'lastName': 'Vidal Puig',
      'username': 'polvidal',
      'email': 'pol@aprop.cat',
      'password': ' Contrasenya1! ',
    });
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.isLoading, isFalse);
  });

  test("Avisa si el nom d'usuari ja està agafat", () async {
    repository.error = AuthFailure.usernameAlreadyInUse;

    final success = await registerPol();

    expect(success, isFalse);
    expect(viewModel.errorMessage, AuthFailure.usernameAlreadyInUse.message);
  });

  test('Mostra un missatge genèric si falla inesperadament', () async {
    repository.error = StateError('error intern');

    final success = await registerPol();

    expect(success, isFalse);
    expect(viewModel.errorMessage, unexpectedAuthErrorMessage);
  });
}
