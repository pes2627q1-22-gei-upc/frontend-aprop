import 'package:flutter/material.dart';

import '../../models/email_action.dart';
import '../../repositories/auth_repository.dart';
import '../view_models/email_action_view_model.dart';
import '../widgets/auth_status_message.dart';
import '../widgets/auth_submit_button.dart';

/// Pàgina que obren els enllaços dels correus a la web de l'app (DP-031).
/// Confirma la verificació i explica a l'usuari que torni a l'app.
// TODO(DP-031): disseny sense mockup.
class EmailActionScreen extends StatefulWidget {
  const EmailActionScreen({
    super.key,
    required this.repository,
    required this.action,
    required this.onContinue,
  });

  final AuthRepository repository;
  final EmailAction action;

  /// Passa a l'app normal (inici de sessió o, si ja n'hi ha, el contingut).
  final VoidCallback onContinue;

  @override
  State<EmailActionScreen> createState() => _EmailActionScreenState();
}

class _EmailActionScreenState extends State<EmailActionScreen> {
  late final EmailActionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EmailActionViewModel(
      repository: widget.repository,
      action: widget.action,
    )..start();
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
                  final status = _viewModel.status;
                  final verified = status == EmailActionStatus.verified;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        verified
                            ? Icons.mark_email_read_outlined
                            : Icons.mail_outline,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Verificació del correu',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...switch (status) {
                        EmailActionStatus.verifying => [
                          const Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Verificant el correu',
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Estem verificant el teu correu…'),
                        ],
                        EmailActionStatus.verified => [
                          const AuthStatusMessage.info(
                            "Correu verificat! Torna a l'app AProp! i toca "
                            "«Ja l'he verificat».",
                          ),
                        ],
                        EmailActionStatus.failed => [
                          AuthStatusMessage.error(
                            _viewModel.errorMessage ?? expiredEmailLinkMessage,
                          ),
                        ],
                        EmailActionStatus.unsupported => [
                          const AuthStatusMessage.error(
                            'Aquest enllaç no es pot obrir aquí.',
                          ),
                        ],
                      },
                      if (status != EmailActionStatus.verifying) ...[
                        const SizedBox(height: 24),
                        AuthSubmitButton(
                          label: 'Continua a AProp!',
                          isLoading: false,
                          onPressed: widget.onContinue,
                        ),
                      ],
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
