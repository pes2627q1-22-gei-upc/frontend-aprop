import 'package:flutter/material.dart';

/// Pregunta seguida d'un enllaç, com «Ja tens compte? Inicia sessió». La
/// pregunta va en gris i l'enllaç en el color principal i en negreta, perquè
/// es vegi clarament on es pot tocar.
class AuthLinkPrompt extends StatelessWidget {
  const AuthLinkPrompt({
    super.key,
    required this.question,
    required this.label,
    required this.onPressed,
  });

  final String question;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, style: TextStyle(color: colors.onSurfaceVariant)),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: Text(label),
        ),
      ],
    );
  }
}
