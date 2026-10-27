import 'package:aprop/features/auth/models/email_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Llegeix l’acció i el codi de l’enllaç del correu', () {
    final action = EmailAction.fromUri(
      Uri.parse(
        'https://frontend-aprop.onrender.com/?mode=verifyEmail'
        '&oobCode=gqUBsrlRp2jAN9D-_5y&apiKey=clau&lang=ca',
      ),
    );

    expect(action?.mode, 'verifyEmail');
    expect(action?.code, 'gqUBsrlRp2jAN9D-_5y');
    expect(action?.isEmailVerification, isTrue);
  });

  test('Sense acció o sense codi, la web s’obre com sempre', () {
    expect(EmailAction.fromUri(Uri.parse('http://localhost:5000/')), isNull);
    expect(
      EmailAction.fromUri(Uri.parse('http://localhost:5000/?mode=verifyEmail')),
      isNull,
    );
    expect(
      EmailAction.fromUri(Uri.parse('http://localhost:5000/?oobCode=abc')),
      isNull,
    );
  });

  test('Un altre tipus d’enllaç no és una verificació', () {
    final action = EmailAction.fromUri(
      Uri.parse('http://localhost:5000/?mode=resetPassword&oobCode=abc'),
    );

    expect(action?.isEmailVerification, isFalse);
  });
}
