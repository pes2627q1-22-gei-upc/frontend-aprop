import '../../../../core/l10n/locale_controller.dart';

/// Validacions dels formularis d'accés. Retornen el missatge d'error o
/// `null` si el valor és correcte.
abstract final class AuthValidators {
  static const minPasswordLength = 8;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _usernamePattern = RegExp(r'^[a-z0-9._]{3,20}$');
  // Amb `unicode`, À o ç compten com a lletres i no com a caràcters especials.
  static final _uppercasePattern = RegExp(r'\p{Lu}', unicode: true);
  static final _lowercasePattern = RegExp(r'\p{Ll}', unicode: true);
  static final _digitPattern = RegExp(r'\p{Nd}', unicode: true);
  static final _specialCharacterPattern = RegExp(
    r'[^\p{L}\p{N}\s]',
    unicode: true,
  );

  static String? notEmpty(String? value, {required String message}) {
    return (value == null || value.trim().isEmpty) ? message : null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return currentL10n.authEmailRequiredField;
    if (!_emailPattern.hasMatch(email)) return currentL10n.authEmailInvalid;
    return null;
  }

  static String? username(String? value) {
    final username = value?.trim() ?? '';

    if (username.isEmpty) return currentL10n.authUsernameRequired;
    if (!_usernamePattern.hasMatch(username)) {
      return currentL10n.authUsernameRules;
    }
    return null;
  }

  /// Criteri de Taiga: mínim 8 caràcters amb majúscula, minúscula, número i
  /// caràcter especial. El missatge diu només el que falta.
  static String? newPassword(String? value) {
    final password = value ?? '';

    final l10n = currentL10n;
    if (password.isEmpty) return l10n.authPasswordRequired;

    final missing = [
      if (password.length < minPasswordLength)
        l10n.authPasswordMissingLength(minPasswordLength),
      if (!_uppercasePattern.hasMatch(password)) l10n.authPasswordMissingUpper,
      if (!_lowercasePattern.hasMatch(password)) l10n.authPasswordMissingLower,
      if (!_digitPattern.hasMatch(password)) l10n.authPasswordMissingDigit,
      if (!_specialCharacterPattern.hasMatch(password))
        l10n.authPasswordMissingSpecial,
    ];
    if (missing.isEmpty) return null;

    final requirements = missing.length == 1
        ? missing.single
        : l10n.authListAnd(
            missing.take(missing.length - 1).join(', '),
            missing.last,
          );
    return l10n.authPasswordMustHave(requirements);
  }

  static String? passwordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return currentL10n.authRepeatPasswordRequired;
    }
    if (value != password) return currentL10n.authPasswordsDiffer;
    return null;
  }
}
