import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/presentation/screens/create_activity_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_activity_repository.dart';

void main() {
  late FakeActivityRepository repository;
  late List<Activity> published;

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    repository = FakeActivityRepository();
    published = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CreateActivityScreen(
          repository: repository,
          creator: const ActivityCreator(name: 'Laia Soler', isFriend: false),
          onCreated: published.add,
          now: () => DateTime(2026, 10, 19, 12),
        ),
      ),
    );
  }

  Future<void> fill(WidgetTester tester, String label, String text) {
    return tester.enterText(find.widgetWithText(TextField, label), text);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    // La descripció té el seu propi desplaçament: fem servir el del formulari.
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Omple el formulari i publica l’activitat', (tester) async {
    await pumpForm(tester);

    await fill(tester, 'Títol', 'Concert a la plaça');
    await fill(tester, 'Descripció', 'Una nit de música');
    await tapVisible(tester, find.text('Tria una categoria'));
    await tester.tap(find.text('Teatre'));
    await tester.pumpAndSettle();
    // La categoria triada surt al camp amb la seva insígnia.
    expect(find.text('Teatre'), findsOneWidget);

    // Data per defecte: demà; hora per defecte: 19.00.
    await tapVisible(tester, find.text('Tria la data i l’hora'));
    await tester.tap(find.text('D’acord'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('D’acord'));
    await tester.pumpAndSettle();
    expect(find.text('Dimarts 20 d’octubre de 2026 · 19.00 h'), findsOneWidget);

    await fill(tester, 'Municipi', 'Vic');
    await fill(tester, 'Preu (opcional)', '5');
    await tapVisible(tester, find.bySemanticsLabel('Imatge 2'));
    await tapVisible(tester, find.text('Publica'));

    expect(published, hasLength(1));
    final sent = repository.created.single;
    expect(sent.category, 'Teatre');
    expect(sent.startsAt, DateTime(2026, 10, 20, 19));
    expect(sent.price, 5);
    expect(sent.imageAsset, 'assets/images/teatre_sota_les_estrelles.jpg');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mostra què falta abans de publicar', (tester) async {
    await pumpForm(tester);

    await tapVisible(tester, find.text('Publica'));

    expect(published, isEmpty);
    expect(repository.created, isEmpty);
    await tester.scrollUntilVisible(
      find.text('Introdueix el títol.'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Introdueix el títol.'), findsOneWidget);
    expect(find.text('Introdueix una descripció.'), findsOneWidget);
    expect(find.text('Tria una categoria.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tria una imatge.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tria una imatge.'), findsOneWidget);
  });
}
