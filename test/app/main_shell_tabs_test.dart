import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/activities/presentation/widgets/map_filter_bar.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_navigation.dart';

/// #273: Inici mostra Descobreix i el mapa té la seva pestanya.
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    await tester.pumpWidget(APropApp(authRepository: auth));
    await tester.pumpAndSettle();
  }

  NavigationBar navigationBar(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar));

  testWidgets('En entrar es veu Inici amb les recomanacions', (tester) async {
    await pumpApp(tester);

    expect(navigationBar(tester).selectedIndex, 0);
    // Capçalera «AProp!» amb el «+» a l'esquerra i la cerca a la dreta.
    final appBar = find.byType(AppBar);
    expect(
      find.descendant(of: appBar, matching: find.bySemanticsLabel('AProp!')),
      findsOneWidget,
    );
    final create = find.byTooltip('Crear activitat');
    final search = find.byKey(const ValueKey('discover-search'));
    expect(create, findsOneWidget);
    expect(search, findsOneWidget);
    expect(tester.getCenter(create).dx, lessThan(tester.getCenter(search).dx));
    expect(find.text('Assistent'), findsOneWidget);
    // El mapa i la llista no hi són.
    expect(find.byType(MapFilterBar), findsNothing);
  });

  testWidgets('Les pestanyes es diuen Inici i Mapa', (tester) async {
    await pumpApp(tester);

    final labels = [
      for (final destination in tester.widgetList<NavigationDestination>(
        find.byType(NavigationDestination),
      ))
        destination.label,
    ];
    expect(labels, ['Inici', 'Agenda', 'Mapa', 'Avisos', 'Perfil']);
  });

  testWidgets('El mapa té la seva pestanya, amb l’assistent i sense «+»', (
    tester,
  ) async {
    await pumpApp(tester);
    await openMapTab(tester);

    expect(navigationBar(tester).selectedIndex, 2);
    // #274: només el mapa, amb la cerca i els filtres a sobre.
    expect(find.byType(MapFilterBar), findsOneWidget);
    expect(find.byKey(const ValueKey('map-search')), findsOneWidget);
    expect(markerIds(tester), contains('demo-jazz'));
    expect(find.text('Assistent'), findsOneWidget);
    expect(find.byTooltip('Crear activitat'), findsNothing);
  });

  testWidgets('La cerca s’obre des de la capçalera d’Inici', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('discover-search')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Cerca'), findsOneWidget);
    expect(navigationBar(tester).selectedIndex, 0);
  });

  testWidgets('La barra del mapa obre la cerca a la mateixa pestanya', (
    tester,
  ) async {
    await pumpApp(tester);
    await openMapTab(tester);

    await tester.tap(find.byKey(const ValueKey('map-search')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Cerca'), findsOneWidget);
    expect(navigationBar(tester).selectedIndex, 2);
  });
}
