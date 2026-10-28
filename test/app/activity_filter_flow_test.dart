import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/activities/presentation/widgets/activities_header.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_card.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_categories_filter_sheet.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoAuthRepository auth;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    await tester.pumpWidget(APropApp(authRepository: auth));
    await tester.pumpAndSettle();
  }

  Finder destination(String label) =>
      find.widgetWithText(NavigationDestination, label);

  Future<void> openCategories(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey('activities-filter-categories')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('activity-filter-category-Teatre')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Filters preserve detail/section navigation and shared enrollment',
    (tester) async {
      await pumpApp(tester);
      await openCategories(tester);
      // A root modal covers the shell navigation, as in the approved mockup.
      expect(destination('Perfil').hitTestable(), findsNothing);
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityCard), findsOneWidget);
      expect(find.text('Teatre sota les estrelles'), findsOneWidget);
      await tester.tap(find.text('M’hi apunto'));
      await tester.pumpAndSettle();
      expect(find.text('Apuntat'), findsOneWidget);
      await tester.tap(find.text('Teatre sota les estrelles'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
      expect(find.text('Apuntat'), findsOneWidget);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityCard), findsOneWidget);
      await tester.tap(destination('Descobreix'));
      await tester.pumpAndSettle();
      expect(find.text('Mirades de Catalunya'), findsOneWidget);
      await tester.tap(destination('Inici'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ActivitiesHeader>(find.byType(ActivitiesHeader))
            .categoriesSelected,
        isTrue,
      );
      expect(find.byType(ActivityCard), findsOneWidget);
      await tester.tap(find.byTooltip('Netejar tots els filtres'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Teatre sota les estrelles'),
        200,
        scrollable: find.descendant(
          of: find.byKey(const PageStorageKey('activities-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(ActivityCard, 'Teatre sota les estrelles'),
          matching: find.text('Apuntat'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Sign-out closes an open draft and the next session starts unfiltered',
    (tester) async {
      await pumpApp(tester);
      await openCategories(tester);
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(ActivityCategoriesFilterSheet), findsNothing);
      expect(find.text('Inicia sessió'), findsOneWidget);
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ActivitiesHeader>(find.byType(ActivitiesHeader))
            .categoriesSelected,
        isFalse,
      );
      expect(find.byTooltip('Netejar tots els filtres'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
