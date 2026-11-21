import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/auth/models/auth_failure.dart';
import 'package:aprop/features/auth/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/activities/fake_enrollment_repository.dart';
import '../features/auth/fake_auth_repository.dart';

/// #10: «Eliminar compte» in Configuració.
void main() {
  late FakeEnrollmentRepository enrollments;

  setUp(() => enrollments = FakeEnrollmentRepository());
  tearDown(() => enrollments.dispose());

  Future<void> openDeleteDialog(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configuració'));
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('profile-delete-account'));
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('profile-settings-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(
    WidgetTester tester,
    AuthRepository auth, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      APropApp(authRepository: auth, enrollmentRepository: enrollments),
    );
    await tester.pumpAndSettle();
  }

  FilledButton confirmButton(WidgetTester tester) =>
      tester.widget<FilledButton>(
        find.byKey(const ValueKey('profile-delete-account-confirm')),
      );

  testWidgets(
    'Cal escriure ELIMINAR; després s’esborra el compte i es torna a l’inici de sessió',
    (tester) async {
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      await pumpApp(tester, auth);
      await openDeleteDialog(tester);

      expect(find.text('Vols eliminar el compte?'), findsOneWidget);
      expect(confirmButton(tester).onPressed, isNull);

      // «Cancel·la» keeps everything.
      await tester.tap(find.text('Cancel·la'));
      await tester.pumpAndSettle();
      expect(find.text('Vols eliminar el compte?'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('profile-delete-account')));
      await tester.pumpAndSettle();
      final word = find.byKey(const ValueKey('profile-delete-account-word'));
      await tester.enterText(word, 'eliminar');
      await tester.pump();
      expect(confirmButton(tester).onPressed, isNotNull);

      await tester.tap(
        find.byKey(const ValueKey('profile-delete-account-confirm')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inicia sessió'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await expectLater(
        auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!'),
        throwsA(AuthFailure.invalidCredentials),
      );
    },
  );

  testWidgets('Si no es pot eliminar, es queda a Configuració i ho diu', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..signedInUser = const AppUser(
        id: 'u1',
        email: 'pol@example.test',
        firstName: 'Pol',
        lastName: 'Vidal',
        username: 'polvidal',
        emailVerified: true,
      );
    await pumpApp(tester, auth);
    auth.error = AuthFailure.network;
    await openDeleteDialog(tester);
    await tester.enterText(
      find.byKey(const ValueKey('profile-delete-account-word')),
      'ELIMINAR',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('profile-delete-account-confirm')),
    );
    await tester.pumpAndSettle();

    expect(auth.deleteAccountCalls, 1);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(
          'No hem pogut eliminar el compte. Torna-ho a provar.',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-delete-account')),
      findsOneWidget,
    );
  });

  testWidgets('El diàleg cap a 320 px amb la lletra al doble', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    await pumpApp(tester, auth, size: const Size(320, 844));
    await openDeleteDialog(tester);

    expect(find.text('Vols eliminar el compte?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
