import '../models/auth_failure.dart';

/// Tradueix el codi d'una `FirebaseAuthException` a un error que la interfície
/// sap explicar. Retorna `null` si l'error no té cap missatge propi.
///
/// No inclou els errors de credencials: només tenen sentit en entrar amb
/// correu i contrasenya ([signInFailureFromFirebaseCode]). En registrar-se o
/// en entrar amb Google, dir «l'usuari o la contrasenya no són correctes»
/// confondria.
AuthFailure? authFailureFromFirebaseCode(String code) {
  return switch (code) {
    'email-already-in-use' => AuthFailure.emailAlreadyInUse,
    'network-request-failed' => AuthFailure.network,
    'too-many-requests' => AuthFailure.tooManyRequests,
    'popup-blocked' => AuthFailure.popupBlocked,
    'invalid-action-code' ||
    'expired-action-code' => AuthFailure.invalidVerificationLink,
    _ => null,
  };
}

/// Com [authFailureFromFirebaseCode], però per a l'inici de sessió amb correu i
/// contrasenya.
AuthFailure? signInFailureFromFirebaseCode(String code) {
  return switch (code) {
    // Per seguretat, Firebase ja no distingeix entre usuari inexistent i
    // contrasenya incorrecta: tots dos són `invalid-credential`.
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-email' ||
    'user-disabled' => AuthFailure.invalidCredentials,
    _ => authFailureFromFirebaseCode(code),
  };
}

/// Separa el `displayName` de Firebase en nom i cognoms pel primer espai. No és
/// exacte amb noms compostos, però és provisional fins que el backend desi el
/// perfil (DP-026).
(String, String) splitDisplayName(String? displayName) {
  final name = displayName?.trim() ?? '';
  final space = name.indexOf(' ');
  if (space == -1) return (name, '');
  return (name.substring(0, space), name.substring(space + 1).trim());
}

/// Treu el codi d'un enllaç de verificació de Firebase
/// (`…/__/auth/action?mode=verifyEmail&oobCode=…`). Accepta també el codi sol i
/// enllaços que algun client de correu embolcalla dins d'un altre (`?q=…`).
/// Retorna `null` si no n'hi troba cap o si l'enllaç és d'una altra acció.
String? verificationCodeFromLink(String text) {
  final link = text.trim();
  if (link.isEmpty) return null;

  final uri = Uri.tryParse(link);
  if (uri == null || !uri.hasScheme) {
    // Sense esquema: el codi sol (no porta espais ni caràcters d'URL).
    return RegExp(r'^[A-Za-z0-9_-]{20,}$').hasMatch(link) ? link : null;
  }

  final params = uri.queryParameters;
  final code = params['oobCode'];
  if (code != null && code.isNotEmpty) {
    final mode = params['mode'];
    return mode == null || mode == 'verifyEmail' ? code : null;
  }

  // Enllaç embolcallat (p. ex. https://www.google.com/url?q=<enllaç>).
  for (final wrapped in [params['q'], params['url'], params['link']]) {
    if (wrapped != null && wrapped != link) {
      final inner = verificationCodeFromLink(wrapped);
      if (inner != null) return inner;
    }
  }
  return null;
}
