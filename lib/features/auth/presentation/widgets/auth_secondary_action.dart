import 'package:flutter/material.dart';

/// Pregunta i botó per a l'acció alternativa de la pantalla, com crear un
/// compte des del login. El botó tonal es distingeix del principal i del de
/// Google sense competir amb el principal.
class AuthSecondaryAction extends StatelessWidget {
  const AuthSecondaryAction({
    super.key,
    required this.question,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String question;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ],
    );
  }
}
