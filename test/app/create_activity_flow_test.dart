import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_card.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Crea una activitat des d’Inici, n’obre la fitxa i surt a la llista',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      await tester.pumpWidget(APropApp(authRepository: auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear activitat'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Crea una activitat'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Títol'),
        'Concert a la plaça',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Descripció'),
        'Una nit de música',
      );
      await tester.tap(find.text('Tria una categoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Música'));
      await tester.pumpAndSettle();
      final form = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Tria la data i l’hora'),
        200,
        scrollable: form,
      );
      await tester.tap(find.text('Tria la data i l’hora'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('D’acord'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('D’acord'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Municipi'), 'Vic');
      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Imatge 1'),
        200,
        scrollable: form,
      );
      await tester.tap(find.bySemanticsLabel('Imatge 1'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Publica'),
        200,
        scrollable: form,
      );
      await tester.tap(find.text('Publica'));
      await tester.pumpAndSettle();

      // La fitxa substitueix el formulari i la creadora hi està apuntada.
      expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
      expect(find.text('Concert a la plaça'), findsOneWidget);
      expect(find.text('Gratuït'), findsOneWidget);
      expect(find.text('Apuntat'), findsOneWidget);

      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Crea una activitat'), findsNothing);
      await tester.scrollUntilVisible(
        find.widgetWithText(ActivityCard, 'Concert a la plaça'),
        300,
        scrollable: find.descendant(
          of: find.byKey(const PageStorageKey<String>('activities-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(
        find.descendant(
          of: find.widgetWithText(ActivityCard, 'Concert a la plaça'),
          matching: find.text('Publicat per Laia Soler'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
