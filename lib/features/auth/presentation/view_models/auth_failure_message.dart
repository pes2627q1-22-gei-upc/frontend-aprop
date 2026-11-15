import '../../models/auth_failure.dart';

const unexpectedAuthErrorMessage =
    "No hem pogut completar l'operació. Torna-ho a provar.";

extension AuthFailureMessage on AuthFailure {
  String get message => switch (this) {
    AuthFailure.invalidCredentials =>
      "L'usuari o la contrasenya no són correctes.",
    AuthFailure.emailAlreadyInUse => 'Ja hi ha un compte amb aquest correu.',
    AuthFailure.usernameAlreadyInUse =>
      "Aquest nom d'usuari ja està agafat. Prova'n un altre.",
    AuthFailure.network =>
      'No hi ha connexió. Comprova la xarxa i torna-ho a provar.',
    AuthFailure.tooManyRequests =>
      'Massa intents seguits. Espera una mica i torna-ho a provar.',
    AuthFailure.emailRequired =>
      'De moment només pots entrar amb el correu electrònic.',
    AuthFailure.popupBlocked =>
      "El navegador ha bloquejat la finestra de Google. Permet les finestres "
          'emergents i torna-ho a provar.',
  };
}
