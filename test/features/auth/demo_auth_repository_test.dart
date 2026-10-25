import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/auth/models/auth_failure.dart';

void main() {
  late DemoAuthRepository repository;

  setUp(() => repository = DemoAuthRepository());

  test('Emet la sessió actual i els canvis', () async {
    final usernames = <String?>[];
    final subscription = repository.authStateChanges().listen(
      (user) => usernames.add(user?.username),
    );

    await repository.signIn(
      usernameOrEmail: 'Laia@aprop.cat',
      password: 'Aprop2026!',
    );
    await repository.signOut();
    await Future<void>.delayed(Duration.zero);

    expect(usernames, [null, 'laiasoler', null]);
    await subscription.cancel();
  });

  test("Permet entrar amb el nom d'usuari", () async {
    await repository.signIn(
      usernameOrEmail: 'LaiaSoler',
      password: 'Aprop2026!',
    );

    final user = await repository.authStateChanges().first;
    expect(user?.email, 'laia@aprop.cat');
  });

  test('Rebutja una contrasenya incorrecta', () {
    expect(
      repository.signIn(
        usernameOrEmail: 'laia@aprop.cat',
        password: 'incorrecta',
      ),
      throwsA(AuthFailure.invalidCredentials),
    );
  });

  test('Registra un compte nou i hi inicia la sessió', () async {
    await repository.register(
      firstName: 'Pol',
      lastName: 'Vidal',
      username: 'polvidal',
      email: 'pol@aprop.cat',
      password: 'Contrasenya1!',
    );

    final user = await repository.authStateChanges().first;
    expect(user?.username, 'polvidal');
    expect(user?.emailVerified, isFalse);
  });

  test('Simula la verificació del correu dels comptes nous', () async {
    await repository.register(
      firstName: 'Pol',
      lastName: 'Vidal',
      username: 'polvidal',
      email: 'pol@aprop.cat',
      password: 'Contrasenya1!',
    );

    expect(await repository.checkEmailVerified(), isTrue);
    expect((await repository.authStateChanges().first)?.emailVerified, isTrue);

    // La verificació es conserva en tornar a entrar.
    await repository.signOut();
    await repository.signIn(
      usernameOrEmail: 'polvidal',
      password: 'Contrasenya1!',
    );
    expect((await repository.authStateChanges().first)?.emailVerified, isTrue);
  });

  test("No permet repetir correu ni nom d'usuari", () {
    expect(
      repository.register(
        firstName: 'Laia',
        lastName: 'Soler',
        username: 'altra',
        email: 'laia@aprop.cat',
        password: 'Contrasenya1!',
      ),
      throwsA(AuthFailure.emailAlreadyInUse),
    );
    expect(
      repository.register(
        firstName: 'Laia',
        lastName: 'Soler',
        username: 'laiasoler',
        email: 'altra@aprop.cat',
        password: 'Contrasenya1!',
      ),
      throwsA(AuthFailure.usernameAlreadyInUse),
    );
  });

  test("El primer accés amb Google no té nom d'usuari", () async {
    expect(await repository.signInWithGoogle(), isTrue);

    final user = await repository.authStateChanges().first;
    expect(user?.emailVerified, isTrue);
    expect(user?.username, isNull);
  });

  test(
    "Conserva el nom d'usuari triat en tornar a entrar amb Google",
    () async {
      await repository.signInWithGoogle();
      await repository.chooseUsername('jordipuig');
      await repository.signOut();
      await repository.signInWithGoogle();

      expect(
        (await repository.authStateChanges().first)?.username,
        'jordipuig',
      );
    },
  );

  test("No deixa triar un nom d'usuari agafat", () async {
    await repository.signInWithGoogle();

    expect(
      repository.chooseUsername('laiasoler'),
      throwsA(AuthFailure.usernameAlreadyInUse),
    );
  });
}
