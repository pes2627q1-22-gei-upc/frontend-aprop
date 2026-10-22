import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/features/auth/data/firebase_auth_failure.dart';
import 'package:aprop/features/auth/models/auth_failure.dart';

void main() {
  const credentialCodes = [
    'invalid-credential',
    'wrong-password',
    'user-not-found',
    'invalid-email',
    'user-disabled',
  ];

  test('En entrar no diu si falla el correu o la contrasenya', () {
    for (final code in credentialCodes) {
      expect(
        signInFailureFromFirebaseCode(code),
        AuthFailure.invalidCredentials,
        reason: code,
      );
    }
  });

  test("Fora de l'inici de sessió no parla de credencials", () {
    // En registrar-se o entrar amb Google, «l'usuari o la contrasenya no són
    // correctes» confondria: es mostra el missatge genèric.
    for (final code in credentialCodes) {
      expect(authFailureFromFirebaseCode(code), isNull, reason: code);
    }
  });

  test('Tradueix els errors que la interfície sap explicar', () {
    for (final translate in [
      authFailureFromFirebaseCode,
      signInFailureFromFirebaseCode,
    ]) {
      expect(translate('email-already-in-use'), AuthFailure.emailAlreadyInUse);
      expect(translate('network-request-failed'), AuthFailure.network);
      expect(translate('too-many-requests'), AuthFailure.tooManyRequests);
      expect(translate('popup-blocked'), AuthFailure.popupBlocked);
    }
  });

  test('Deixa els errors desconeguts per al missatge genèric', () {
    expect(authFailureFromFirebaseCode('internal-error'), isNull);
    expect(signInFailureFromFirebaseCode('internal-error'), isNull);
  });

  test('Separa el nom i els cognoms pel primer espai', () {
    expect(splitDisplayName('Pol Vidal Puig'), ('Pol', 'Vidal Puig'));
    expect(splitDisplayName('  Laia   Soler '), ('Laia', 'Soler'));
    expect(splitDisplayName('Sukhjeet'), ('Sukhjeet', ''));
    expect(splitDisplayName(null), ('', ''));
    expect(splitDisplayName('   '), ('', ''));
  });
}
