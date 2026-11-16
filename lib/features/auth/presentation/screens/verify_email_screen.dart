import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../view_models/verify_email_view_model.dart';
import '../widgets/auth_link_prompt.dart';
import '../widgets/auth_status_message.dart';
import '../widgets/auth_submit_button.dart';

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
                        'Verifica el teu correu',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          text: "T'hem enviat un enllaç a ",
                          children: [
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  ". Obre'l per activar el compte i després "
                                  'torna aquí.',
                            ),
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
                        label: "Ja l'he verificat",
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
                              ? 'Torna a enviar el correu ($secondsLeft s)'
                              : 'Torna a enviar el correu',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthLinkPrompt(
                        question: "T'has equivocat de correu?",
                        label: 'Tanca la sessió',
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
