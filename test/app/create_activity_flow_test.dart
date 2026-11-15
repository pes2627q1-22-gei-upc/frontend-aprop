import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
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
      final catalogue = DemoActivityRepository();
      await tester.pumpWidget(
        APropApp(authRepository: auth, activityRepository: catalogue),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Crear activitat'));
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
      await tester.tap(find.bySemanticsLabel('Música'));
      await tester.pumpAndSettle();
      final form = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Tria la data i l’hora'),
        200,
        scrollable: form,
      );
      await tester.tap(find.text('Tria la data i l’hora'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fet'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Municipi (opcional)'),
        'Vic',
      );
      // La portada per defecte ja és vàlida: no cal triar-ne cap.
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
      expect(
        (await catalogue.getActivityById('demo-created-1'))!.creator!.userId,
        'demo-laiasoler',
      );

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
      await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
      await tester.pumpAndSettle();
      final profileScroll = find.descendant(
        of: find.byKey(const PageStorageKey('profile-scroll')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Creats per mi'),
        200,
        scrollable: profileScroll,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Creats per mi'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Concert a la plaça'),
        200,
        scrollable: profileScroll,
      );
      expect(find.text('Concert a la plaça'), findsOneWidget);
    },
  );
}
