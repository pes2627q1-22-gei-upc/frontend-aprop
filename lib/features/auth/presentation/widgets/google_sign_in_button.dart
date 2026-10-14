import 'package:flutter/material.dart';

/// Separador «o» seguit del botó per entrar amb Google.
///
/// Un [onPressed] nul desactiva el botó: l'accés amb Google depèn de Firebase,
/// que encara no està configurat.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'o',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Tooltip(
          message: onPressed == null
              ? 'Accés amb Google disponible properament'
              : 'Continua amb Google',
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Continua amb Google'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ],
    );
  }
}
