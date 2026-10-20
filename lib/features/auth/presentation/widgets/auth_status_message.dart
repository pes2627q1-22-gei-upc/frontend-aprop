import 'package:flutter/material.dart';

/// Missatge general d'un formulari, d'error o informatiu. És una regió viva:
/// el lector de pantalla l'anuncia quan apareix o canvia, sense que l'usuari
/// hagi d'anar a buscar-lo.
class AuthStatusMessage extends StatelessWidget {
  const AuthStatusMessage.error(this.message, {super.key}) : isError = true;

  const AuthStatusMessage.info(this.message, {super.key}) : isError = false;

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: TextStyle(color: isError ? colors.error : colors.primary),
      ),
    );
  }
}
