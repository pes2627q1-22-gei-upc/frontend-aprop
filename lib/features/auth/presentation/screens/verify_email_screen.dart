import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../view_models/verify_email_view_model.dart';
import '../widgets/auth_link_prompt.dart';
import '../widgets/auth_status_message.dart';
import '../widgets/auth_submit_button.dart';
import '../../../../core/l10n/locale_controller.dart';

/// Pantalla de bloqueig: es mostra mentre l'usuari de la sessió no ha
/// verificat el correu.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.repository,
    required this.email,
  });

  final AuthRepository repository;
  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final VerifyEmailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VerifyEmailViewModel(repository: widget.repository);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, child) {
                  final errorMessage = _viewModel.errorMessage;
                  final infoMessage = _viewModel.infoMessage;
                  final secondsLeft = _viewModel.cooldownSecondsLeft;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.mark_email_unread_outlined,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.l10n.authVerifyTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          text: '${context.l10n.authVerifySentTo} ',
                          children: [
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: context.l10n.authVerifyOpenIt),
                          ],
                        ),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (errorMessage != null) ...[
                        AuthStatusMessage.error(errorMessage),
                        const SizedBox(height: 12),
                      ],
                      if (infoMessage != null) ...[
                        AuthStatusMessage.info(infoMessage),
                        const SizedBox(height: 12),
                      ],
                      AuthSubmitButton(
                        label: context.l10n.authAlreadyVerified,
                        isLoading: _viewModel.isChecking,
                        onPressed: _viewModel.checkVerification,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _viewModel.canResend
                            ? _viewModel.resendEmail
                            : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        // L'espai no separable evita que «(27 s)» es parteixi
                        // entre dues línies amb la lletra gran.
                        child: Text(
                          secondsLeft > 0
                              ? context.l10n.authResendEmailIn(secondsLeft)
                              : context.l10n.authResendEmail,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthLinkPrompt(
                        question: context.l10n.authWrongEmail,
                        label: context.l10n.authSignOutLink,
                        onPressed: _viewModel.signOut,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
