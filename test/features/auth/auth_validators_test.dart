import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/features/auth/presentation/view_models/auth_validators.dart';

void main() {
  test('Valida el correu', () {
    expect(AuthValidators.email(' laia@aprop.cat '), isNull);
    expect(AuthValidators.email(''), isNotNull);
    expect(AuthValidators.email('laia@aprop'), isNotNull);
    expect(AuthValidators.email('laia aprop.cat'), isNotNull);
  });

  test("Valida el nom d'usuari", () {
    expect(AuthValidators.username('laia.soler_92'), isNull);
    expect(AuthValidators.username('abc'), isNull);
    expect(AuthValidators.username('ab'), isNotNull);
    expect(AuthValidators.username('a' * 21), isNotNull);
    expect(AuthValidators.username('LaiaSoler'), isNotNull);
    expect(AuthValidators.username('laia soler'), isNotNull);
  });

  test('Exigeix 8 caràcters, majúscula, minúscula, número i especial', () {
    expect(AuthValidators.newPassword('Aprop2026!'), isNull);
    expect(AuthValidators.newPassword('Àpròp 2026ç·'), isNull);
    expect(AuthValidators.newPassword(''), 'Introdueix una contrasenya.');
    expect(AuthValidators.newPassword('Ap2026!'), isNotNull);
    expect(AuthValidators.newPassword('aprop2026!'), isNotNull);
    expect(AuthValidators.newPassword('APROP2026!'), isNotNull);
    expect(AuthValidators.newPassword('AproPaprop!'), isNotNull);
    expect(AuthValidators.newPassword('Aprop2026'), isNotNull);
  });

  test('Diu només els requisits que falten', () {
    expect(
      AuthValidators.newPassword('Aprop2026'),
      'Ha de tenir un caràcter especial.',
    );
    expect(
      AuthValidators.newPassword('aprop'),
      'Ha de tenir almenys 8 caràcters, una majúscula, un número i '
      'un caràcter especial.',
    );
  });

  test('Comprova que les contrasenyes coincideixen', () {
    expect(
      AuthValidators.passwordConfirmation('Aprop2026!', 'Aprop2026!'),
      isNull,
    );
    expect(
      AuthValidators.passwordConfirmation('Aprop2025!', 'Aprop2026!'),
      isNotNull,
    );
    expect(AuthValidators.passwordConfirmation('', 'Aprop2026!'), isNotNull);
  });

  test('Rebutja camps obligatoris buits', () {
    expect(AuthValidators.notEmpty('Laia', message: 'Buit'), isNull);
    expect(AuthValidators.notEmpty('   ', message: 'Buit'), 'Buit');
  });
}
