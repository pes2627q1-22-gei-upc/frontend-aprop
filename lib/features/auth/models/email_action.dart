/// Acció d'un enllaç dels correus de Firebase Auth quan s'obre a la web de
/// l'app: Firebase hi afegeix `?mode=verifyEmail&oobCode=…` si l'URL d'acció
/// de les plantilles apunta a la web (DP-031).
class EmailAction {
  const EmailAction({required this.mode, required this.code});

  /// `verifyEmail`, `resetPassword`, `recoverEmail`…
  final String mode;

  /// Codi d'un sol ús (`oobCode`) que Firebase confirma.
  final String code;

  bool get isEmailVerification => mode == 'verifyEmail';

  /// Retorna `null` si l'adreça no porta cap acció.
  static EmailAction? fromUri(Uri uri) {
    final mode = uri.queryParameters['mode']?.trim() ?? '';
    final code = uri.queryParameters['oobCode']?.trim() ?? '';
    if (mode.isEmpty || code.isEmpty) return null;
    return EmailAction(mode: mode, code: code);
  }
}
