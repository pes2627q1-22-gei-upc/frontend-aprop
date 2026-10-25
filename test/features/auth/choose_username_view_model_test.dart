import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/features/auth/models/auth_failure.dart';
import 'package:aprop/features/auth/presentation/view_models/auth_failure_message.dart';
import 'package:aprop/features/auth/presentation/view_models/choose_username_view_model.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ChooseUsernameViewModel viewModel;

  setUp(() {
    repository = FakeAuthRepository();
    viewModel = ChooseUsernameViewModel(repository: repository);
  });

  tearDown(() => viewModel.dispose());

  test("Desa el nom d'usuari sense espais", () async {
    final result = viewModel.submit(' jordipuig ');
    expect(viewModel.isLoading, isTrue);

    expect(await result, isTrue);
    expect(repository.lastCall, {'username': 'jordipuig'});
    expect(viewModel.isLoading, isFalse);
  });

  test('No crida el repositori si el nom no és vàlid', () async {
    expect(await viewModel.submit('J'), isFalse);

    expect(
      viewModel.usernameError,
      'Entre 3 i 20 caràcters: minúscules, números, punt o guió baix.',
    );
    expect(repository.lastCall, isNull);
  });

  test("Avisa si el nom d'usuari ja està agafat", () async {
    repository.error = AuthFailure.usernameAlreadyInUse;

    expect(await viewModel.submit('laiasoler'), isFalse);
    expect(viewModel.errorMessage, AuthFailure.usernameAlreadyInUse.message);
  });

  test('Mostra un missatge genèric si falla inesperadament', () async {
    repository.error = Exception('error intern');

    await viewModel.submit('jordipuig');

    expect(viewModel.errorMessage, unexpectedAuthErrorMessage);
  });

  test("En modificar el nom se n'esborren els errors", () async {
    await viewModel.submit('');
    expect(viewModel.usernameError, isNotNull);

    var notified = false;
    viewModel.addListener(() => notified = true);
    viewModel.onUsernameChanged();

    expect(viewModel.usernameError, isNull);
    expect(notified, isTrue);
  });

  test('No envia el nom dues vegades mentre espera', () async {
    repository.pending = Completer<void>();
    final first = viewModel.submit('jordipuig');

    expect(await viewModel.submit('jordipuig2'), isFalse);

    repository.pending!.complete();
    await first;
    expect(repository.lastCall, {'username': 'jordipuig'});
  });
}
