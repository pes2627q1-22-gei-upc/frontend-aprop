import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/features/auth/models/auth_failure.dart';
import 'package:aprop/features/auth/presentation/view_models/auth_failure_message.dart';
import 'package:aprop/features/auth/presentation/view_models/verify_email_view_model.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late VerifyEmailViewModel viewModel;

  setUp(() {
    repository = FakeAuthRepository();
    // Sense compte enrere, per provar els enviaments sense esperar.
    viewModel = VerifyEmailViewModel(
      repository: repository,
      resendCooldown: Duration.zero,
    );
  });

  tearDown(() => viewModel.dispose());

  test('No deixa reenviar el correu fins que acaba el compte enrere', () async {
    final waitingViewModel = VerifyEmailViewModel(repository: repository);
    addTearDown(waitingViewModel.dispose);

    expect(waitingViewModel.cooldownSecondsLeft, 60);
    expect(waitingViewModel.canResend, isFalse);

    await waitingViewModel.resendEmail();

    expect(repository.verificationEmailsSent, 0);
  });

  test('Avisa si el correu encara no està verificat', () async {
    await viewModel.checkVerification();

    expect(viewModel.errorMessage, emailNotVerifiedMessage);
    expect(viewModel.isChecking, isFalse);
  });

  test('No mostra cap error si el correu ja està verificat', () async {
    repository.emailVerified = true;

    await viewModel.checkVerification();

    expect(viewModel.errorMessage, isNull);
  });

  test('Torna a enviar el correu i ho confirma', () async {
    await viewModel.checkVerification();
    await viewModel.resendEmail();

    expect(repository.verificationEmailsSent, 1);
    expect(viewModel.infoMessage, verificationEmailSentMessage);
    expect(viewModel.errorMessage, isNull);
  });

  test("Mostra l'error si no es pot enviar el correu", () async {
    repository.error = AuthFailure.network;

    await viewModel.resendEmail();

    expect(viewModel.errorMessage, AuthFailure.network.message);
    expect(viewModel.infoMessage, isNull);
    expect(viewModel.isResending, isFalse);
  });

  test('No fa una altra acció mentre una està en curs', () async {
    repository.pending = Completer<void>();

    final resend = viewModel.resendEmail();
    await viewModel.resendEmail();
    await viewModel.checkVerification();
    expect(viewModel.isBusy, isTrue);

    repository.pending!.complete();
    await resend;

    expect(repository.verificationEmailsSent, 1);
    expect(viewModel.isBusy, isFalse);
  });

  test('Mostra un missatge genèric si falla inesperadament', () async {
    repository.error = StateError('error intern');

    await viewModel.checkVerification();

    expect(viewModel.errorMessage, unexpectedAuthErrorMessage);
  });

  test("Demana l'enllaç si està buit i no crida el repositori", () async {
    await viewModel.verifyWithLink('   ');

    expect(viewModel.linkError, emptyVerificationLinkMessage);
    expect(repository.lastCall, isNull);
  });

  test("Verifica amb l'enllaç enganxat, sense espais", () async {
    await viewModel.verifyWithLink('  https://exemple/?oobCode=abc  ');

    expect(repository.lastCall, {'link': 'https://exemple/?oobCode=abc'});
    expect(viewModel.linkError, isNull);
    expect(viewModel.isApplyingLink, isFalse);
  });

  test("Explica que l'enllaç no és vàlid", () async {
    repository.error = AuthFailure.invalidVerificationLink;

    await viewModel.verifyWithLink('https://exemple/?oobCode=vell');

    expect(viewModel.linkError, AuthFailure.invalidVerificationLink.message);

    viewModel.onLinkChanged();
    expect(viewModel.linkError, isNull);
  });

  test("No fa res més mentre verifica l'enllaç", () async {
    repository.pending = Completer<void>();
    final pending = viewModel.verifyWithLink('https://exemple/?oobCode=abc');

    expect(viewModel.isApplyingLink, isTrue);
    expect(viewModel.isBusy, isTrue);
    await viewModel.checkVerification();
    expect(repository.lastCall, {'link': 'https://exemple/?oobCode=abc'});

    repository.pending!.complete();
    await pending;
  });
}
