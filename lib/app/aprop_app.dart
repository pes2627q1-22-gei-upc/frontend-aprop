import 'package:flutter/material.dart';

import 'navigation/main_shell.dart';
import 'theme/app_theme.dart';

class APropApp extends StatelessWidget {
  const APropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AProp!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(), //pantalla inicial de la aplicación, que contiene la navegación principal y las diferentes secciones de la app.
    );
  }
}
