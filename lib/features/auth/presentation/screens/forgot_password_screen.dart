import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../view_models/forgot_password_view_model.dart';
import '../widgets/auth_link_prompt.dart';
import '../widgets/auth_status_message.dart';
import '../widgets/auth_submit_button.dart';

/// «He oblidat la contrasenya»: envia un enllaç al correu per triar-ne una de
/// nova. L'enllaç s'obre a la pàgina de Firebase, que la canvia.
// TODO(DP-047): disseny i textos sense mockup.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.repository,
    this.initialEmail = '',
  });

  final AuthRepository repository;

  /// El correu que ja s'havia escrit al login, si n'era un.
  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  late final ForgotPasswordViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ForgotPasswordViewModel(repository: widget.repository);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _send() {
    FocusScope.of(context).unfocus();
    _viewModel.send(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recupera la contrasenya')),
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
                        Icons.lock_reset,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Has oblidat la contrasenya?',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Escriu el correu del teu compte i t'enviarem un "
                        "enllaç per triar-ne una de nova.",
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.send,
                        autofillHints: const [AutofillHints.email],
                        onChanged: (_) => _viewModel.onEmailChanged(),
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          labelText: 'Correu',
                          errorText: _viewModel.emailError,
                          prefixIcon: const Icon(Icons.mail_outline),
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
                        // L'espai no separable evita que «(27 s)» es parteixi
                        // entre dues línies amb la lletra gran.
                        label: !_viewModel.hasSent
                            ? "Envia l'enllaç"
                            : secondsLeft > 0
                            ? "Torna a enviar l'enllaç ($secondsLeft s)"
                            : "Torna a enviar l'enllaç",
                        isLoading: _viewModel.isSending,
                        onPressed: _viewModel.canSend ? _send : null,
                      ),
                      const SizedBox(height: 24),
                      AuthLinkPrompt(
                        question: 'Ja la recordes?',
                        label: "Torna a l'inici de sessió",
                        onPressed: () => Navigator.of(context).maybePop(),
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
