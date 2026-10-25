import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../view_models/choose_username_view_model.dart';
import '../widgets/auth_link_prompt.dart';
import '../widgets/auth_status_message.dart';
import '../widgets/auth_submit_button.dart';

/// El compte encara no té nom d'usuari (primer accés amb Google) i no es pot
/// entrar a l'app fins que en triï un.
class ChooseUsernameScreen extends StatefulWidget {
  const ChooseUsernameScreen({
    super.key,
    required this.repository,
    required this.firstName,
    this.rejectedUsername,
  });

  final AuthRepository repository;
  final String firstName;

  /// Nom que es va demanar en registrar-se i ja era d'una altra persona. Si
  /// no és nul, la pantalla explica per què se'n demana un altre.
  final String? rejectedUsername;

  @override
  State<ChooseUsernameScreen> createState() => _ChooseUsernameScreenState();
}

class _ChooseUsernameScreenState extends State<ChooseUsernameScreen> {
  final _usernameController = TextEditingController();
  late final ChooseUsernameViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ChooseUsernameViewModel(repository: widget.repository);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  /// Un compte de Google pot no tenir nom.
  String _greeting() {
    final firstName = widget.firstName.trim();
    return firstName.isEmpty ? 'Hola!' : 'Hola, $firstName!';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // Si va bé no naveguem: AuthGate veu el nom d'usuari i mostra l'app.
    await _viewModel.submit(_usernameController.text);
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.alternate_email,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Tria el teu nom d'usuari",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // TODO(DP-025): text sense mockup. No parla de Google:
                      // provisionalment també hi arriba qui entra amb correu
                      // en un altre dispositiu (DP-026).
                      Text(
                        '${_greeting()} Tria el nom amb què et trobaran a '
                        "l'app.",
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (widget.rejectedUsername case final rejected?) ...[
                        const SizedBox(height: 16),
                        AuthStatusMessage.info(
                          "El nom «$rejected» ja és d'una altra persona. "
                          "Tria'n un altre.",
                        ),
                      ],
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usernameController,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newUsername],
                        onChanged: (_) => _viewModel.onUsernameChanged(),
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: "Nom d'usuari",
                          errorText: _viewModel.usernameError,
                          prefixIcon: const Icon(Icons.alternate_email),
                          helperText:
                              'Minúscules, números, punt o guió baix (3-20).',
                          // Com al registre: amb la lletra gran no s'ha de
                          // tallar.
                          helperMaxLines: 10,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (errorMessage != null) ...[
                        AuthStatusMessage.error(errorMessage),
                        const SizedBox(height: 12),
                      ],
                      AuthSubmitButton(
                        label: 'Continua',
                        isLoading: _viewModel.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 24),
                      AuthLinkPrompt(
                        question: 'No és el teu compte?',
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
