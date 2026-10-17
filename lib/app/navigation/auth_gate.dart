import 'package:flutter/material.dart';

import '../../features/auth/models/app_user.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/auth/repositories/auth_repository.dart';
import 'main_shell.dart';

/// Mostra el login si no hi ha sessió, la verificació del correu si encara no
/// està verificat i, si tot és correcte, l'aplicació.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Es crea un sol cop: si es creés a build, cada redibuix tornaria a subscriure's.
  late final Stream<AppUser?> _authState = widget.authRepository
      .authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return LoginScreen(repository: widget.authRepository);
        }

        if (!user.emailVerified) {
          return VerifyEmailScreen(
            repository: widget.authRepository,
            email: user.email,
          );
        }

        return MainShell(user: user, onSignOut: widget.authRepository.signOut);
      },
    );
  }
}
