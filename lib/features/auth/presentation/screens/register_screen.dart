import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../view_models/register_view_model.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/password_field.dart';

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

    // AuthGate ja mostra l'app sota aquesta pantalla; la tanquem perquè es vegi.
    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Crea un compte')),
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
                        'Uneix-te a AProp! per apuntar-te a activitats i '
                        'crear-ne de noves.',
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
                          labelText: 'Nom',
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
                          labelText: 'Cognoms',
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
                          labelText: "Nom d'usuari",
                          errorText: _viewModel.fieldError(
                            RegisterField.username,
                          ),
                          prefixIcon: const Icon(Icons.alternate_email),
                          helperText:
                              'Minúscules, números, punt o guió baix (3-20).',
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
                          labelText: 'Correu electrònic',
                          errorText: _viewModel.fieldError(RegisterField.email),
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _passwordController,
                        label: 'Contrasenya',
                        helperText:
                            'Mínim 8 caràcters, amb majúscula, minúscula, '
                            'número i caràcter especial.',
                        errorText: _viewModel.fieldError(
                          RegisterField.password,
                        ),
                        onChanged: (_) =>
                            _viewModel.onFieldChanged(RegisterField.password),
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _confirmationController,
                        label: 'Repeteix la contrasenya',
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
                        Text(
                          errorMessage,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                      ],
                      AuthSubmitButton(
                        label: 'Crea el compte',
                        isLoading: _viewModel.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                      const GoogleSignInButton(),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Ja tens compte?'),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Inicia sessió'),
                          ),
                        ],
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
