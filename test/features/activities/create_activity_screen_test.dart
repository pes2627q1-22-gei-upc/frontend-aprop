import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_location_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/presentation/screens/create_activity_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'fake_activity_repository.dart';

void main() {
  late FakeActivityRepository repository;
  late List<Activity> published;

  Future<void> pumpForm(WidgetTester tester, {DateTime? now}) async {
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
          locationRepository: const DemoLocationRepository(),
          creator: const ActivityCreator(name: 'Laia Soler', isFriend: false),
          onCreated: published.add,
          now: () => now ?? DateTime(2026, 10, 19, 12),
        ),
      ),
    );
  }

  Future<void> fill(WidgetTester tester, String label, String text) async {
    final field = find.widgetWithText(TextField, label);
    // Els camps de sota no es construeixen fins que no s'hi arriba.
    await tester.scrollUntilVisible(
      field,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(field, text);
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

    // La portada es canvia des del llapis.
    await tester.tap(find.byTooltip('Canvia la imatge'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Imatge 2'));
    await tester.pumpAndSettle();

    await fill(tester, 'Títol', 'Concert a la plaça');
    await fill(tester, 'Descripció', 'Una nit de música');
    await tapVisible(tester, find.bySemanticsLabel('Teatre'));

    // Data per defecte: demà; hora per defecte: 19.00.
    await tapVisible(tester, find.text('Tria la data i l’hora'));
    await tester.tap(find.text('Fet'));
    await tester.pumpAndSettle();
    expect(find.text('Dimarts 20 d’octubre de 2026 · 19.00 h'), findsOneWidget);

    await fill(tester, 'Municipi (opcional)', 'Vic');
    await fill(tester, 'Indicacions (opcional)', ' Entrada pel pati ');
    await fill(tester, 'Preu (opcional)', '5');
    await tapVisible(tester, find.text('Publica'));

    expect(published, hasLength(1));
    final sent = repository.created.single;
    expect(sent.category, 'Teatre');
    expect(sent.startsAt, DateTime(2026, 10, 20, 19));
    expect(sent.price, 5);
    expect(sent.imageAsset, 'assets/images/teatre_sota_les_estrelles.jpg');
    expect(sent.directions, 'Entrada pel pati');
    // En escriure «Vic», el marcador s'ha posat al centre del municipi.
    expect(sent.location, const GeoPoint(latitude: 41.9301, longitude: 2.2549));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Es poden triar diverses categories, la modalitat i l’horari', (
    tester,
  ) async {
    await pumpForm(tester);

    await fill(tester, 'Títol', 'Xerrada');
    await fill(tester, 'Descripció', 'En directe');
    await tapVisible(tester, find.bySemanticsLabel('Música'));
    await tapVisible(tester, find.bySemanticsLabel('Teatre'));
    await tapVisible(tester, find.text('Tria la data i l’hora'));
    await tester.tap(find.text('Fet'));
    await tester.pumpAndSettle();
    await fill(tester, 'Més sobre l’horari (opcional)', 'Durada: 1 h');

    expect(
      find.widgetWithText(TextField, 'Enllaç per connectar-s’hi (opcional)'),
      findsNothing,
    );
    await tapVisible(tester, find.text('En línia'));
    await fill(
      tester,
      'Enllaç per connectar-s’hi (opcional)',
      'https://meet.example.cat/xerrada',
    );
    await tapVisible(tester, find.text('Activitat permanent'));
    await tapVisible(tester, find.text('Publica'));

    final sent = repository.created.single;
    expect(sent.categories, ['Música', 'Teatre']);
    expect(sent.schedule, '19.00 h · Durada: 1 h');
    expect(sent.modality, ActivityModality.online);
    expect(sent.onlineUrl, 'https://meet.example.cat/xerrada');
    expect(sent.isPermanent, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('La data per defecte és demà també quan acaba l’horari d’estiu', (
    tester,
  ) async {
    await pumpForm(tester, now: DateTime(2026, 10, 25, 23, 30));
    await tapVisible(tester, find.text('Tria la data i l’hora'));
    expect(find.text('Dilluns 26 d’octubre de 2026'), findsOneWidget);
    final confirm = find.widgetWithText(FilledButton, 'Fet');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.text('Dilluns 26 d’octubre de 2026 · 19.00 h'), findsOneWidget);
  });

  testWidgets('El mapa mostra el marcador i tocar-lo l’ajusta', (tester) async {
    await pumpForm(tester);
    GoogleMap map() => tester.widget<GoogleMap>(find.byType(GoogleMap));
    // Fins al text d'ajuda, que és just a sota del mapa.
    await tester.scrollUntilVisible(
      find.textContaining('toca el mapa'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(map().markers, isEmpty);
    expect(
      find.text('Escriu el municipi o toca el mapa per marcar el lloc.'),
      findsOneWidget,
    );

    await fill(tester, 'Municipi (opcional)', 'Vic');
    await tester.pump();
    expect(map().markers.single.position, const LatLng(41.9301, 2.2549));
    expect(
      find.text('Marcador al centre del municipi: toca el lloc exacte.'),
      findsOneWidget,
    );

    map().onTap!(const LatLng(41.9300, 2.2545));
    await tester.pump();
    expect(map().markers.single.position, const LatLng(41.9300, 2.2545));
    expect(
      find.text('Lloc marcat. Pots tornar a tocar el mapa per canviar-lo.'),
      findsOneWidget,
    );
  });

  testWidgets('El panell de la portada té les plantilles i la pujada', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.byTooltip('Canvia la imatge'));
    await tester.pumpAndSettle();

    expect(find.text('Imatge de portada'), findsOneWidget);
    // Pujar fotos és la tasca #94: el botó hi és però desactivat.
    final upload = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Puja una foto (properament)'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(upload.onPressed, isNull);
    for (var index = 1; index <= 3; index++) {
      expect(find.bySemanticsLabel('Imatge $index'), findsOneWidget);
    }
  });

  group('Panell de data i hora', () {
    Future<void> openSheet(WidgetTester tester) async {
      await pumpForm(tester);
      await tapVisible(tester, find.text('Tria la data i l’hora'));
    }

    // Una posició de roda són 40 píxels: arrossegar cap amunt avança.
    Future<void> turn(WidgetTester tester, String wheel, int steps) async {
      await tester.drag(find.byKey(ValueKey(wheel)), Offset(0, -40.0 * steps));
      await tester.pumpAndSettle();
    }

    testWidgets('Les rodes canvien el resum i el resultat', (tester) async {
      await openSheet(tester);
      expect(find.text('Dimarts 20 d’octubre de 2026'), findsOneWidget);
      expect(find.text('19.00 h'), findsWidgets);

      await turn(tester, 'start-time', 2);
      await turn(tester, 'start-month', 1);

      expect(find.text('Divendres 20 de novembre de 2026'), findsOneWidget);
      expect(find.text('19.30 h'), findsWidgets);

      await tester.tap(find.text('Fet'));
      await tester.pumpAndSettle();
      expect(
        find.text('Divendres 20 de novembre de 2026 · 19.30 h'),
        findsOneWidget,
      );
    });

    testWidgets('No deixa triar un moment que ja ha passat', (tester) async {
      await openSheet(tester);

      // Del 20 al 18 d'octubre, abans d'ara (19 d'octubre a les 12.00).
      await turn(tester, 'start-day', -2);

      expect(find.text('L’inici ha de ser posterior a ara.'), findsOneWidget);
      final done = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Fet'),
      );
      expect(done.onPressed, isNull);
    });

    testWidgets('Cancel·lar no canvia la data', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Cancel·la'));
      await tester.pumpAndSettle();

      expect(find.text('Tria la data i l’hora'), findsOneWidget);
    });
  });

  group('Data de fi', () {
    testWidgets('Fins que no hi ha inici no es pot triar', (tester) async {
      await pumpForm(tester);

      await tapVisible(tester, find.text('Tria primer l’inici'));

      expect(find.text('Data i hora de fi'), findsNothing);
    });

    testWidgets('Es tria, es publica i es pot treure', (tester) async {
      await pumpForm(tester);
      await tapVisible(tester, find.text('Tria la data i l’hora'));
      await tester.tap(find.text('Fet'));
      await tester.pumpAndSettle();

      // Per defecte, dues hores després de l'inici (20 d'octubre, 19.00 h).
      await tapVisible(tester, find.text('Sense data de fi'));
      expect(find.text('Data i hora de fi'), findsOneWidget);
      expect(find.text('21.00 h'), findsWidgets);
      await tester.tap(find.text('Fet'));
      await tester.pumpAndSettle();
      expect(
        find.text('Dimarts 20 d’octubre de 2026 · 21.00 h'),
        findsOneWidget,
      );

      await tapVisible(tester, find.byTooltip('Treu la data de fi'));
      expect(find.text('Sense data de fi'), findsOneWidget);
    });

    testWidgets('No deixa triar una fi anterior a l’inici', (tester) async {
      await pumpForm(tester);
      await tapVisible(tester, find.text('Tria la data i l’hora'));
      await tester.tap(find.text('Fet'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Sense data de fi'));

      // De les 21.00 a les 18.00, abans de l'inici (19.00).
      await tester.drag(find.byKey(const ValueKey('end-time')), Offset(0, 480));
      await tester.pumpAndSettle();

      expect(find.text('La fi ha de ser posterior a l’inici.'), findsOneWidget);
      final done = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Fet'),
      );
      expect(done.onPressed, isNull);
    });
  });

  testWidgets('Es pot publicar sense municipi', (tester) async {
    await pumpForm(tester);
    await fill(tester, 'Títol', 'Concert');
    await fill(tester, 'Descripció', 'Una nit de música');
    await tapVisible(tester, find.bySemanticsLabel('Teatre'));
    await tapVisible(tester, find.text('Tria la data i l’hora'));
    await tester.tap(find.text('Fet'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Publica'));

    expect(published, hasLength(1));
    expect(repository.created.single.municipality, isEmpty);
    expect(repository.created.single.endsAt, isNull);
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
  });
}
