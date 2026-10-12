import 'package:flutter/material.dart';

import '../features/auth/repositories/auth_repository.dart';
import 'navigation/auth_gate.dart';
import 'theme/app_theme.dart';

class APropApp extends StatelessWidget {
  const APropApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AProp!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AuthGate(authRepository: authRepository), //pantalla inicial: AuthGate decide si mostrar el login o la navegación principal de la app según si hay sesión iniciada.
    );
  }
}
