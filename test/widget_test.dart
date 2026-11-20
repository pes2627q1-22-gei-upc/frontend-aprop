import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';

import 'app/app_navigation.dart';

Future<APropApp> signedInApp() async {
  final repository = DemoAuthRepository();
  await repository.signIn(
    usernameOrEmail: 'laia@aprop.cat',
    password: 'Aprop2026!',
  );
  return APropApp(authRepository: repository);
}

void main() {
  testWidgets('Mostra les activitats de demostració al mapa', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await signedInApp());
    await tester.pumpAndSettle();
    await openMapTab(tester);

    expect(tester.takeException(), isNull);
    // #274: el mapa ocupa la pantalla, sense capçalera.
    expect(find.byType(AppBar), findsNothing);
    expect(markerIds(tester), isNotEmpty);
    // Els filtres, en una sola fila de xips a sobre del mapa.
    final dates = find.byKey(const ValueKey('activities-filter-dates'));
    final categories = find.byKey(
      const ValueKey('activities-filter-categories'),
    );
    expect(tester.getTopLeft(categories).dy, tester.getTopLeft(dates).dy);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('map-search'))).dy,
      lessThan(tester.getTopLeft(dates).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Permet anar a Agenda i tornar al mapa', (tester) async {
    await tester.pumpWidget(await signedInApp());
    await tester.pumpAndSettle();
    await openMapTab(tester);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Agenda'), findsOneWidget);
    expect(find.byTooltip('Mes següent').hitTestable(), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Mapa'));
    await tester.pumpAndSettle();

    expect(markerIds(tester), isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Opening details keeps navigation and restores the map card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await signedInApp());
    await tester.pumpAndSettle();
    await openMapTab(tester);

    await tapMarker(tester, 'demo-theatre');
    await tester.tap(find.text('Teatre sota les estrelles'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
    expect(find.text('Tarragona'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2, // Mapa
    );

    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Agenda'), findsOneWidget);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Mapa'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Activitat'), findsNothing);
    // La targeta del marcador continua oberta.
    expect(find.byTooltip('Tancar'), findsOneWidget);
    expect(find.text('Teatre sota les estrelles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
