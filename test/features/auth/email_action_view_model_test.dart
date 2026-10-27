import 'package:aprop/features/auth/models/auth_failure.dart';
import 'package:aprop/features/auth/models/email_action.dart';
import 'package:aprop/features/auth/presentation/view_models/auth_failure_message.dart';
import 'package:aprop/features/auth/presentation/view_models/email_action_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  EmailActionViewModel viewModel(String mode) {
    final viewModel = EmailActionViewModel(
      repository: repository,
      action: EmailAction(mode: mode, code: 'codi-del-correu'),
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  test('Confirma el codi de l’enllaç i dona el correu per verificat', () async {
    final verification = viewModel('verifyEmail');
    expect(verification.status, EmailActionStatus.verifying);

    await verification.start();

    expect(repository.lastCall, {'code': 'codi-del-correu'});
    expect(verification.status, EmailActionStatus.verified);
  });

  test('El codi només es confirma un cop', () async {
    final verification = viewModel('verifyEmail');

    await verification.start();
    repository.lastCall = null;
    await verification.start();

    expect(repository.lastCall, isNull);
  });

  test('Si l’enllaç ha caducat, ho explica', () async {
    repository.error = AuthFailure.invalidVerificationLink;
    final verification = viewModel('verifyEmail');

    await verification.start();

    expect(verification.status, EmailActionStatus.failed);
    expect(verification.errorMessage, expiredEmailLinkMessage);
  });

  test('Sense connexió, mostra el missatge de la xarxa', () async {
    repository.error = AuthFailure.network;
    final verification = viewModel('verifyEmail');

    await verification.start();

    expect(verification.errorMessage, AuthFailure.network.message);
  });

  test('Un altre tipus d’enllaç no es confirma', () async {
    final verification = viewModel('resetPassword');

    await verification.start();

    expect(verification.status, EmailActionStatus.unsupported);
    expect(repository.lastCall, isNull);
  });
}
