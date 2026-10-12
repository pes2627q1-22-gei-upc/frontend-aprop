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

    if (email.isEmpty) return 'Introdueix el correu.';
    if (!_emailPattern.hasMatch(email)) return 'El correu no és vàlid.';
    return null;
  }

  static String? username(String? value) {
    final username = value?.trim() ?? '';

    if (username.isEmpty) return "Introdueix un nom d'usuari.";
    if (!_usernamePattern.hasMatch(username)) {
      return 'Entre 3 i 20 caràcters: minúscules, números, punt o guió baix.';
    }
    return null;
  }

  /// Criteri de Taiga: mínim 8 caràcters amb majúscula, minúscula, número i
  /// caràcter especial. El missatge diu només el que falta.
  static String? newPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) return 'Introdueix una contrasenya.';

    final missing = [
      if (password.length < minPasswordLength)
        'almenys $minPasswordLength caràcters',
      if (!_uppercasePattern.hasMatch(password)) 'una majúscula',
      if (!_lowercasePattern.hasMatch(password)) 'una minúscula',
      if (!_digitPattern.hasMatch(password)) 'un número',
      if (!_specialCharacterPattern.hasMatch(password)) 'un caràcter especial',
    ];
    if (missing.isEmpty) return null;

    final requirements = missing.length == 1
        ? missing.single
        : '${missing.take(missing.length - 1).join(', ')} i ${missing.last}';
    return 'Ha de tenir $requirements.';
  }

  static String? passwordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) return 'Repeteix la contrasenya.';
    if (value != password) return 'Les contrasenyes no coincideixen.';
    return null;
  }
}
