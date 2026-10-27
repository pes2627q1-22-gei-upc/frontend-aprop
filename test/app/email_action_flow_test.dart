import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/models/email_action.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/auth/fake_auth_repository.dart';

void main() {
  testWidgets(
    'La web oberta des de l’enllaç del correu verifica i després continua a l’app',
    (tester) async {
      final auth = FakeAuthRepository();
      await tester.pumpWidget(
        APropApp(
          authRepository: auth,
          emailAction: const EmailAction(mode: 'verifyEmail', code: 'codi'),
        ),
      );
      await tester.pumpAndSettle();

      // No es mostra l'inici de sessió fins que l'usuari continua.
      expect(find.text('Verificació del correu'), findsOneWidget);
      expect(find.textContaining('Correu verificat!'), findsOneWidget);
      expect(auth.lastCall, {'code': 'codi'});
      expect(find.text('Inicia sessió'), findsNothing);

      await tester.tap(find.text('Continua a AProp!'));
      await tester.pumpAndSettle();

      expect(find.text('Inicia sessió'), findsOneWidget);
    },
  );

  testWidgets('Sense acció a l’adreça, l’app s’obre com sempre', (
    tester,
  ) async {
    await tester.pumpWidget(APropApp(authRepository: FakeAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Verificació del correu'), findsNothing);
    expect(find.text('Inicia sessió'), findsOneWidget);
  });
}
