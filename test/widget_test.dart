import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';

Future<APropApp> signedInApp() async {
  final repository = DemoAuthRepository();
  await repository.signIn(
    usernameOrEmail: 'laia@aprop.cat',
    password: 'Aprop2026!',
  );
  return APropApp(authRepository: repository);
}

void main() {
  testWidgets('Mostra les activitats de demostració', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await signedInApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('AProp!'), findsOneWidget);
    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);
    expect(
      tester.getTopLeft(find.widgetWithText(OutlinedButton, 'Categories')).dy,
      tester.getTopLeft(find.widgetWithText(OutlinedButton, 'Dates')).dy,
    );

    final headerPosition = tester.getTopLeft(find.bySemanticsLabel('AProp!'));
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.bySemanticsLabel('AProp!')), headerPosition);
    expect(
      find.text('Teatre sota les estrelles').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Permet anar a Agenda i tornar a la llista', (tester) async {
    await tester.pumpWidget(await signedInApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Agenda'), findsOneWidget);
    expect(find.byTooltip('Mes següent').hitTestable(), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Inici'));
    await tester.pumpAndSettle();

    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Opening details keeps navigation and restores the list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await signedInApp());
    await tester.pumpAndSettle();

    final list = find.byKey(const PageStorageKey<String>('activities-list'));
    await tester.drag(list, const Offset(0, -500));
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    final offset = tester.state<ScrollableState>(scrollable).position.pixels;

    await tester.tap(find.text('Teatre sota les estrelles'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
    expect(find.text('Tarragona'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Agenda'), findsOneWidget);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Inici'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Activitat'), findsNothing);
    expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
    expect(
      find.text('Teatre sota les estrelles').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
