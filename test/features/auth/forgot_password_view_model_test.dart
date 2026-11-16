import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/features/auth/models/auth_failure.dart';
import 'package:aprop/features/auth/presentation/view_models/auth_failure_message.dart';
import 'package:aprop/features/auth/presentation/view_models/forgot_password_view_model.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ForgotPasswordViewModel viewModel;

  setUp(() {
    repository = FakeAuthRepository();
    viewModel = ForgotPasswordViewModel(repository: repository);
  });

  tearDown(() => viewModel.dispose());

  test('Valida el correu abans d\'enviar res', () async {
    await viewModel.send('   ');
    expect(viewModel.emailError, 'Introdueix el correu.');

    await viewModel.send('laia@aprop');
    expect(viewModel.emailError, 'El correu no és vàlid.');

    expect(repository.passwordResetEmails, isEmpty);
    expect(viewModel.hasSent, isFalse);
  });

  test('Envia l\'enllaç sense espais i no diu si el compte existeix', () async {
    await viewModel.send('  laia@aprop.cat ');

    expect(repository.passwordResetEmails, ['laia@aprop.cat']);
    expect(viewModel.hasSent, isTrue);
    expect(viewModel.infoMessage, passwordResetSentMessage);
    expect(viewModel.infoMessage, startsWith('Si hi ha un compte'));
    expect(viewModel.errorMessage, isNull);
  });

  test('Després d\'enviar, espera 60 segons per tornar-ho a fer', () async {
    await viewModel.send('laia@aprop.cat');

    expect(viewModel.cooldownSecondsLeft, 60);
    expect(viewModel.canSend, isFalse);
    await viewModel.send('laia@aprop.cat');
    expect(repository.passwordResetEmails, hasLength(1));
  });

  test('Sense espera, es pot tornar a enviar de seguida', () async {
    final noWait = ForgotPasswordViewModel(
      repository: repository,
      resendCooldown: Duration.zero,
    );
    addTearDown(noWait.dispose);

    await noWait.send('laia@aprop.cat');
    await noWait.send('laia@aprop.cat');

    expect(repository.passwordResetEmails, hasLength(2));
  });

  test('Explica els errors coneguts i els inesperats', () async {
    repository.error = AuthFailure.tooManyRequests;
    await viewModel.send('laia@aprop.cat');
    expect(viewModel.errorMessage, AuthFailure.tooManyRequests.message);
    expect(viewModel.hasSent, isFalse);
    expect(viewModel.canSend, isTrue);

    repository.error = StateError('error intern');
    await viewModel.send('laia@aprop.cat');
    expect(viewModel.errorMessage, unexpectedAuthErrorMessage);
  });

  test('En canviar el correu se n\'esborra l\'error', () async {
    await viewModel.send('no és un correu');
    expect(viewModel.emailError, isNotNull);

    viewModel.onEmailChanged();

    expect(viewModel.emailError, isNull);
  });

  test('No envia dues vegades mentre espera la resposta', () async {
    repository.pending = Completer<void>();

    final first = viewModel.send('laia@aprop.cat');
    expect(viewModel.isSending, isTrue);
    await viewModel.send('laia@aprop.cat');

    repository.pending!.complete();
    await first;
    expect(repository.passwordResetEmails, hasLength(1));
    expect(viewModel.isSending, isFalse);
  });
}
