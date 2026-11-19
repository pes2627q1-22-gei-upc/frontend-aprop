import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../view_models/register_view_model.dart';
import '../widgets/auth_link_prompt.dart';
import '../widgets/auth_status_message.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/password_field.dart';
import '../../../../core/l10n/locale_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  late final RegisterViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RegisterViewModel(repository: widget.repository);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final success = await _viewModel.register(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      passwordConfirmation: _confirmationController.text,
    );

    // AuthGate ja mostra la verificació del correu sota aquesta pantalla; la
    // tanquem perquè es vegi.
    if (success && mounted) Navigator.of(context).pop();
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();

    final success = await _viewModel.signInWithGoogle();

    // Igual que en crear el compte: AuthGate ja mostra el pas següent a sota.
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.authCreateAccountLink)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, child) {
                  final errorMessage = _viewModel.errorMessage;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.authRegisterIntro,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.givenName],
                        onChanged: (_) =>
                            _viewModel.onFieldChanged(RegisterField.firstName),
                        decoration: InputDecoration(
                          labelText: context.l10n.authFirstName,
                          errorText: _viewModel.fieldError(
                            RegisterField.firstName,
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.familyName],
                        onChanged: (_) =>
                            _viewModel.onFieldChanged(RegisterField.lastName),
                        decoration: InputDecoration(
                          labelText: context.l10n.authLastName,
                          errorText: _viewModel.fieldError(
                            RegisterField.lastName,
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usernameController,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newUsername],
                        onChanged: (_) =>
                            _viewModel.onFieldChanged(RegisterField.username),
                        decoration: InputDecoration(
                          labelText: context.l10n.authUsernameLabel,
                          errorText: _viewModel.fieldError(
                            RegisterField.username,
                          ),
                          prefixIcon: const Icon(Icons.alternate_email),
                          helperText: context.l10n.authUsernameHelper,
                          // Sense límit pràctic: amb la lletra gran no hi
                          // cap en una línia i no s'ha de tallar.
                          helperMaxLines: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        onChanged: (_) =>
                            _viewModel.onFieldChanged(RegisterField.email),
                        decoration: InputDecoration(
                          labelText: context.l10n.authEmail,
                          errorText: _viewModel.fieldError(RegisterField.email),
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _passwordController,
                        label: context.l10n.authPassword,
                        helperText: context.l10n.authPasswordHelper,
                        errorText: _viewModel.fieldError(
                          RegisterField.password,
                        ),
                        onChanged: (_) =>
                            _viewModel.onFieldChanged(RegisterField.password),
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _confirmationController,
                        label: context.l10n.authRepeatPassword,
                        errorText: _viewModel.fieldError(
                          RegisterField.passwordConfirmation,
                        ),
                        onChanged: (_) => _viewModel.onFieldChanged(
                          RegisterField.passwordConfirmation,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      if (errorMessage != null) ...[
                        AuthStatusMessage.error(errorMessage),
                        const SizedBox(height: 12),
                      ],
                      AuthSubmitButton(
                        label: context.l10n.authCreateAccountButton,
                        isLoading: _viewModel.isLoading,
                        onPressed: _viewModel.isGoogleLoading ? null : _submit,
                      ),
                      const SizedBox(height: 16),
                      GoogleSignInButton(
                        isLoading: _viewModel.isGoogleLoading,
                        onPressed: _viewModel.isLoading
                            ? null
                            : _signInWithGoogle,
                      ),
                      const SizedBox(height: 24),
                      AuthLinkPrompt(
                        question: context.l10n.authHaveAccount,
                        label: context.l10n.authLoginTitle,
                        onPressed: () => Navigator.of(context).pop(),
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
