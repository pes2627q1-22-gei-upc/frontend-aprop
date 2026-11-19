import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';

/// Separador «o» seguit del botó per entrar amb Google.
///
/// Un [onPressed] nul desactiva el botó, per exemple mentre s'envia el
/// formulari. Mentre carrega, el logotip es substitueix per un indicador.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                context.l10n.authOr,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: isLoading
              ? SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    semanticsLabel: context.l10n.loading,
                    color: colors.onSurfaceVariant,
                  ),
                )
              // El logotip té colors propis: quan el botó està desactivat
              // l'atenuem com la resta del contingut.
              : Opacity(
                  opacity: enabled ? 1 : 0.38,
                  child: Image.asset(
                    'assets/icons/google_g.png',
                    width: 20,
                    height: 20,
                    excludeFromSemantics: true,
                  ),
                ),
          label: Text(context.l10n.authContinueWithGoogle),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}
