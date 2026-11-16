import 'package:flutter/material.dart';

import '../../../../core/widgets/aprop_logo.dart';
import '../../repositories/auth_repository.dart';
import '../view_models/login_view_model.dart';
import '../widgets/auth_secondary_action.dart';
import '../widgets/auth_status_message.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/password_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel(repository: widget.repository);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // Si va bé no naveguem: AuthGate veu la sessió nova i mostra l'app.
    await _viewModel.signIn(
      usernameOrEmail: _usernameOrEmailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();

    // Com amb el formulari: si va bé, AuthGate mostra el que toqui.
    await _viewModel.signInWithGoogle();
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RegisterScreen(repository: widget.repository),
      ),
    );
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
                      const APropLogo(height: 96),
                      const SizedBox(height: 24),
                      Text(
                        'Inicia sessió',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Troba plans culturals a prop teu.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _usernameOrEmailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        onChanged: (_) => _viewModel.onFieldChanged(
                          LoginField.usernameOrEmail,
                        ),
                        decoration: InputDecoration(
                          labelText: "Nom d'usuari o correu",
                          errorText: _viewModel.fieldError(
                            LoginField.usernameOrEmail,
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _passwordController,
                        label: 'Contrasenya',
                        errorText: _viewModel.fieldError(LoginField.password),
                        onChanged: (_) =>
                            _viewModel.onFieldChanged(LoginField.password),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      if (errorMessage != null) ...[
                        AuthStatusMessage.error(errorMessage),
                        const SizedBox(height: 12),
                      ],
                      AuthSubmitButton(
                        label: 'Entra',
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
                      const SizedBox(height: 32),
                      AuthSecondaryAction(
                        question: 'Encara no tens compte?',
                        label: 'Crea un compte',
                        icon: Icons.person_add_alt_1_outlined,
                        onPressed: _openRegister,
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
