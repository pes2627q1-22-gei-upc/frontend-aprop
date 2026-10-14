import 'package:flutter/material.dart';

import '../../features/auth/models/app_user.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/repositories/auth_repository.dart';
import 'main_shell.dart';

/// Mostra el login o l'aplicació segons si hi ha una sessió iniciada.
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

        return MainShell(user: user, onSignOut: widget.authRepository.signOut);
      },
    );
  }
}
