import 'package:flutter/material.dart';

import '../../../../core/widgets/aprop_logo.dart';
import '../../repositories/auth_repository.dart';
import '../view_models/login_view_model.dart';
import '../widgets/auth_secondary_action.dart';
import '../widgets/auth_status_message.dart';
import '../widgets/auth_submit_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/password_field.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../../../../core/l10n/locale_controller.dart';

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

  void _openForgotPassword() {
    // Si al camp ja hi ha un correu (i no un nom d'usuari), ja ve escrit.
    final typed = _usernameOrEmailController.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ForgotPasswordScreen(
          repository: widget.repository,
          initialEmail: typed.contains('@') ? typed : '',
        ),
      ),
    );
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
                        context.l10n.authLoginTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.authLoginSubtitle,
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
                          labelText: context.l10n.authUsernameOrEmail,
                          errorText: _viewModel.fieldError(
                            LoginField.usernameOrEmail,
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _passwordController,
                        label: context.l10n.authPassword,
                        errorText: _viewModel.fieldError(LoginField.password),
                        onChanged: (_) =>
                            _viewModel.onFieldChanged(LoginField.password),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: _viewModel.isBusy
                              ? null
                              : _openForgotPassword,
                          child: Text(context.l10n.forgotLink),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (errorMessage != null) ...[
                        AuthStatusMessage.error(errorMessage),
                        const SizedBox(height: 12),
                      ],
                      AuthSubmitButton(
                        label: context.l10n.authSignIn,
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
                        question: context.l10n.authNoAccount,
                        label: context.l10n.authCreateAccountLink,
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
