import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';

/// Botó principal dels formularis. Mentre carrega es desactiva i mostra un
/// indicador en lloc del text. Un [onPressed] nul el desactiva sense
/// l'indicador, per exemple mentre s'entra amb Google.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      child: isLoading
          ? SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                semanticsLabel: context.l10n.loading,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Text(label),
    );
  }
}
