import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';

/// Camp de contrasenya amb un botó per mostrar-ne o amagar-ne el text.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _isObscured,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        // Sense límit pràctic: amb la lletra gran els requisits s'han de
        // llegir sencers.
        helperMaxLines: 10,
        errorText: widget.errorText,
        errorMaxLines: 3,
        prefixIcon: const Icon(Icons.lock_outline),
        // Fora del recorregut del focus: si no, «Següent» al teclat va a parar
        // a aquest botó i no al camp següent, i el que s'escriu es perd.
        suffixIcon: ExcludeFocusTraversal(
          child: IconButton(
            tooltip: _isObscured
                ? context.l10n.authShowPassword
                : context.l10n.authHidePassword,
            icon: Icon(
              _isObscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(() => _isObscured = !_isObscured),
          ),
        ),
      ),
    );
  }
}
