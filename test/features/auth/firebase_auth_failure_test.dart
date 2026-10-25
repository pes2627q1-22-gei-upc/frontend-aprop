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

  group("Codi de l'enllaç de verificació", () {
    const code = 'Eg85jLnBHWtW65F3lfpzlXjgrET_vr-Au4SG6GMY6hUAAAGhcnnlcg';
    const link =
        'https://aprop-919ec.firebaseapp.com/__/auth/action?mode=verifyEmail'
        '&oobCode=$code&apiKey=AIzaClauAntiga&lang=ca';

    test("El treu de l'enllaç del correu", () {
      expect(verificationCodeFromLink(link), code);
      expect(verificationCodeFromLink('  $link\n'), code);
    });

    test('Accepta el codi sol i enllaços embolcallats', () {
      expect(verificationCodeFromLink(code), code);
      final wrapped = Uri.parse('https://www.google.com/url')
          .replace(queryParameters: {'q': link})
          .toString();
      expect(verificationCodeFromLink(wrapped), code);
    });

    test("Rebutja enllaços d'altres accions i text que no és un enllaç", () {
      expect(
        verificationCodeFromLink(
          link.replaceFirst('verifyEmail', 'resetPassword'),
        ),
        isNull,
      );
      expect(verificationCodeFromLink('https://aprop-919ec.web.app/'), isNull);
      expect(verificationCodeFromLink('hola, què tal'), isNull);
      expect(verificationCodeFromLink(''), isNull);
    });

    test("Un codi caducat o ja fet servir és un enllaç no vàlid", () {
      expect(
        authFailureFromFirebaseCode('invalid-action-code'),
        AuthFailure.invalidVerificationLink,
      );
      expect(
        authFailureFromFirebaseCode('expired-action-code'),
        AuthFailure.invalidVerificationLink,
      );
    });
  });
}
