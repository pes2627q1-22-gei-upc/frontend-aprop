import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/geo_bounds.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/presentation/screens/activities_screen.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_map_view_model.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_view_model.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:aprop/features/activities/presentation/widgets/activities_map.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_map_groups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'fake_activity_map_repository.dart';
import 'fake_activity_repository.dart';
import 'fake_enrollment_repository.dart';

void main() {
  late List<String> opened;
  late List<String> openedFromMap;
  late List<double> overlays;

  Future<void> pumpInici(
    WidgetTester tester, {
    List<Activity>? activities,
    ActivitiesMapViewModel? mapViewModel,
    Set<String> enrolled = const {},
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    opened = [];
    openedFromMap = [];
    overlays = [];

    final repository = activities == null
        ? DemoActivityRepository()
        : (FakeActivityRepository()..activities = activities);
    final viewModel = ActivitiesViewModel(repository: repository)..load();
    final enrollments = EnrollmentViewModel(
      userId: 'test-user',
      repository: FakeEnrollmentRepository()..emit('test-user', enrolled),
    )..load();
    addTearDown(viewModel.dispose);
    addTearDown(enrollments.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ActivitiesScreen(
            viewModel: viewModel,
            enrollmentViewModel: enrollments,
            onActivitySelected: opened.add,
            onMapOverlayChanged: overlays.add,
            mapViewModel: mapViewModel,
            onMapActivitySelected: openedFromMap.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMap(WidgetTester tester) async {
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
  }

  GoogleMap map(WidgetTester tester) =>
      tester.widget<GoogleMap>(find.byType(GoogleMap));

  Marker marker(WidgetTester tester, String id) =>
      map(tester).markers.singleWhere((m) => m.markerId.value == id);

  testWidgets('Inici obre la llista i el botó «Mapa» mostra el mapa', (
    tester,
  ) async {
    await pumpInici(tester);
    expect(find.byType(GoogleMap), findsNothing);
    expect(find.text('Jazz al parc'), findsOneWidget);

    await openMap(tester);
    expect(find.byType(GoogleMap), findsOneWidget);

    // CA3: la llista sempre es pot tornar a obrir.
    await tester.tap(find.text('Llista'));
    await tester.pumpAndSettle();
    expect(find.byType(GoogleMap), findsNothing);
    expect(find.text('Jazz al parc'), findsOneWidget);
  });

  testWidgets('Cada activitat té el seu marcador, agrupable i del seu tipus', (
    tester,
  ) async {
    await pumpInici(tester);
    await openMap(tester);

    expect(map(tester).markers, hasLength(3));
    // A la web, el control de càmera no queda sota «Crear activitat».
    expect(
      map(tester).webCameraControlPosition,
      WebCameraControlPosition.rightTop,
    );
    // Els grups els fa l'app, no Google: a la web i al mòbil són iguals.
    expect(map(tester).clusterManagers, isEmpty);
    expect(map(tester).markers.map((m) => m.markerId.value).toSet(), {
      'demo-jazz',
      'demo-exhibition',
      'demo-theatre',
    });

    String asset(String id) =>
        (marker(tester, id).icon as AssetMapBitmap).assetName;
    expect(asset('demo-jazz'), 'assets/icons/marker_official.png');
    // Teatre sota les estrelles el publica Laia Soler, que és amiga.
    expect(asset('demo-theatre'), 'assets/icons/marker_friend.png');
  });

  testWidgets('Tocar un marcador mostra la targeta, que obre la fitxa', (
    tester,
  ) async {
    await pumpInici(tester);
    await openMap(tester);

    marker(tester, 'demo-theatre').onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Teatre sota les estrelles'), findsOneWidget);
    expect(find.text('Publicat per Laia Soler'), findsOneWidget);
    expect(find.text('Amiga'), findsOneWidget);

    // El mapa avisa de quant ocupa la targeta, per apartar-hi els botons, i
    // la llegenda queda per sobre de la targeta.
    final cardTop = tester.getTopLeft(find.byType(Card).last).dy;
    final mapBottom = tester.getBottomLeft(find.byType(GoogleMap)).dy;
    expect(overlays.last, closeTo(mapBottom - cardTop, 1));
    expect(tester.getBottomLeft(find.text('Llegenda')).dy, lessThan(cardTop));

    // Qualsevol lloc de la targeta obre la fitxa, no només el títol.
    await tester.tap(find.text('Publicat per Laia Soler'));
    expect(opened, ['demo-theatre']);
    await tester.tap(find.text('Teatre sota les estrelles'));
    expect(opened, ['demo-theatre', 'demo-theatre']);

    // Des de la targeta es pot apuntar sense obrir la fitxa.
    final card = find.byType(Card).last;
    await tester.tap(
      find.descendant(of: card, matching: find.text('M’hi apunto')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.text('Apuntat')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Desapunta’m')),
      findsOneWidget,
    );
    expect(opened, hasLength(2));

    // A la web, el mapa també rep el clic fet a la targeta: no l'ha de tancar.
    map(tester).onTap!(const LatLng(41.4, 2.1));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tancar'), findsOneWidget);
    // Tampoc obre el marcador que hi hagi just darrere de la targeta.
    marker(tester, 'demo-jazz').onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Teatre sota les estrelles'), findsOneWidget);
    expect(find.text('Jazz al parc'), findsNothing);

    await tester.tap(find.byTooltip('Tancar'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tancar'), findsNothing);
    // En tancar-la, els botons tornen a baix.
    expect(overlays.last, 0);
  });

  testWidgets('Amb un panell a sobre, el mapa no es mou ni respon', (
    tester,
  ) async {
    await pumpInici(tester);
    await openMap(tester);
    bool locked() => !map(tester).scrollGesturesEnabled;
    expect(locked(), isFalse);

    // Panell de dates (l'obre Inici).
    await tester.tap(find.byKey(const ValueKey('activities-filter-dates')));
    await tester.pumpAndSettle();
    expect(locked(), isTrue);
    expect(map(tester).zoomGesturesEnabled, isFalse);
    marker(tester, 'demo-theatre').onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Teatre sota les estrelles'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(locked(), isFalse);

    // Panell de categories.
    await tester.tap(
      find.byKey(const ValueKey('activities-filter-categories')),
    );
    await tester.pumpAndSettle();
    expect(locked(), isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(locked(), isFalse);

    // Llegenda (l'obre el mapa).
    await tester.tap(find.text('Llegenda'));
    await tester.pumpAndSettle();
    expect(locked(), isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(locked(), isFalse);

    // Un toc al mapa just després d'un clic a sobre seu es pren pel mateix
    // clic (DP-045): la persona no toca tan de pressa.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    marker(tester, 'demo-theatre').onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Teatre sota les estrelles'), findsOneWidget);
  });

  testWidgets('La targeta del marcador diu si ja hi estàs apuntat', (
    tester,
  ) async {
    await pumpInici(tester, enrolled: {'demo-theatre'});
    await openMap(tester);

    marker(tester, 'demo-theatre').onTap!();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(Card).last,
        matching: find.text('Apuntat'),
      ),
      findsOneWidget,
    );

    marker(tester, 'demo-jazz').onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Jazz al parc'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(Card).last,
        matching: find.text('Apuntat'),
      ),
      findsNothing,
    );
  });

  testWidgets('Tocar el mapa tanca la targeta', (tester) async {
    await pumpInici(tester);
    await openMap(tester);

    marker(tester, 'demo-jazz').onTap!();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tancar'), findsOneWidget);

    map(tester).onTap!(const LatLng(41.5, 2.0));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tancar'), findsNothing);
  });

  group('Grups de marcadors', () {
    Activity at(String id, String title, GeoPoint location, int day) =>
        Activity(
          id: id,
          title: title,
          category: 'Música',
          municipality: 'Girona',
          startsAt: DateTime(2026, 11, day, 19),
          imageAsset: '',
          source: ActivitySource.culturalAgenda,
          location: location,
        );
    const auditori = GeoPoint(latitude: 41.98, longitude: 2.81);

    Marker group(WidgetTester tester) =>
        map(tester).markers
            .singleWhere((m) => m.markerId.value.startsWith('grup:'));

    testWidgets(
      'Si són al mateix lloc, en mostra la llista per data i obre la fitxa',
      (tester) async {
        await pumpInici(
          tester,
          activities: [
            at('cor', 'Cor Maragall', auditori, 8),
            at('orgue', 'Concert d’orgue', auditori, 7),
            at('lluny', 'Lluny d’aquí', cataloniaCenter, 9),
          ],
        );
        await openMap(tester);

        // Un sol marcador per a les dues de l'auditori, i el sol a part.
        expect(map(tester).markers.map((m) => m.markerId.value).toSet(), {
          'grup:cor:2',
          'lluny',
        });
        group(tester).onTap!();
        await tester.pumpAndSettle();

        expect(find.text('2 activitats en aquest lloc'), findsOneWidget);
        expect(find.byTooltip('Tancar'), findsNothing);
        expect(
          tester.getTopLeft(find.text('Concert d’orgue')).dy,
          lessThan(tester.getTopLeft(find.text('Cor Maragall')).dy),
        );
        await tester.tap(find.text('Concert d’orgue'));
        await tester.pumpAndSettle();
        expect(opened, ['orgue']);

        // Un marcador sol continua mostrant la seva targeta.
        // Un toc al mapa just després d'un clic a sobre seu es pren pel mateix
        // clic (DP-045): la persona no toca tan de pressa.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 600)),
        );
        marker(tester, 'lluny').onTap!();
        await tester.pumpAndSettle();
        expect(find.byTooltip('Tancar'), findsOneWidget);
      },
    );

    testWidgets('Si són escampats, no obre cap llista i tanca la targeta', (
      tester,
    ) async {
      await pumpInici(
        tester,
        activities: [
          // Dos llocs de Barcelona a uns quants carrers: amb el zoom inicial
          // es tapen, però no són el mateix lloc.
          at(
            'a',
            'Plaça',
            const GeoPoint(latitude: 41.3881, longitude: 2.1874),
            8,
          ),
          at(
            'b',
            'Teatre',
            const GeoPoint(latitude: 41.40, longitude: 2.16),
            9,
          ),
          // Lleida: prou lluny de Barcelona per no ajuntar-s'hi.
          at(
            'lluny',
            'Lluny d’aquí',
            const GeoPoint(latitude: 41.6176, longitude: 0.6200),
            10,
          ),
        ],
      );
      await openMap(tester);
      marker(tester, 'lluny').onTap!();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tancar'), findsOneWidget);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 600)),
      );

      // S'hi apropa el mapa (a les proves no n'hi ha).
      group(tester).onTap!();
      await tester.pumpAndSettle();

      expect(find.textContaining('activitats en aquest lloc'), findsNothing);
      expect(find.byTooltip('Tancar'), findsNothing);
    });

    testWidgets('En apropar el mapa, el grup es separa', (tester) async {
      await pumpInici(
        tester,
        activities: [
          at(
            'a',
            'Plaça',
            const GeoPoint(latitude: 41.3881, longitude: 2.1874),
            8,
          ),
          at(
            'b',
            'Teatre',
            const GeoPoint(latitude: 41.40, longitude: 2.16),
            9,
          ),
        ],
      );
      await openMap(tester);
      expect(map(tester).markers.map((m) => m.markerId.value), ['grup:a:2']);

      // Els grups es refan quan el mapa s'acaba de moure, no a cada pas.
      map(tester).onCameraMove!(
        const CameraPosition(target: LatLng(41.39, 2.17), zoom: 14),
      );
      await tester.pump();
      expect(map(tester).markers.map((m) => m.markerId.value), ['grup:a:2']);
      map(tester).onCameraIdle!();
      await tester.pump();
      expect(map(tester).markers.map((m) => m.markerId.value).toSet(), {
        'a',
        'b',
      });
    });
  });

  test('Uns metres de diferència són el mateix lloc; uns carrers, no', () {
    GeoBounds around(double degrees) => GeoBounds(
      southWest: const GeoPoint(latitude: 41.3881, longitude: 2.1874),
      northEast: GeoPoint(
        latitude: 41.3881 + degrees,
        longitude: 2.1874 + degrees,
      ),
    );

    expect(isSamePlace(around(0)), isTrue);
    expect(isSamePlace(around(0.0001)), isTrue);
    expect(isSamePlace(around(0.001)), isFalse);
  });

  testWidgets('Les activitats sense ubicació no surten i la llegenda ho diu', (
    tester,
  ) async {
    final withLocation = (await DemoActivityRepository().getActivityById(
      'demo-jazz',
    ))!;
    final withoutLocation = Activity(
      id: 'no-location',
      title: 'Sense lloc',
      category: 'Música',
      municipality: 'Poble',
      startsAt: DateTime(2026, 11, 1, 19),
      imageAsset: 'assets/images/jazz_al_parc.jpg',
      source: ActivitySource.community,
    );
    await pumpInici(tester, activities: [withLocation, withoutLocation]);
    await openMap(tester);

    expect(map(tester).markers.map((m) => m.markerId.value), ['demo-jazz']);

    await tester.tap(find.text('Llegenda'));
    await tester.pumpAndSettle();
    expect(find.text('Activitat de l’Agenda Cultural'), findsOneWidget);
    expect(find.text('Publicada per una amistat'), findsOneWidget);
    expect(
      find.text('1 activitat no té ubicació i només surt a la llista.'),
      findsOneWidget,
    );
  });

  group('Amb el backend', () {
    const area = GeoBounds(
      southWest: GeoPoint(latitude: 41.3, longitude: 2.0),
      northEast: GeoPoint(latitude: 41.5, longitude: 2.2),
    );
    final concert = Activity(
      id: '1282',
      title: 'Música a la plaça',
      category: 'Activitat',
      municipality: 'Barcelona',
      startsAt: DateTime(2026, 11, 7),
      imageAsset: '',
      source: ActivitySource.culturalAgenda,
      location: const GeoPoint(latitude: 41.39, longitude: 2.17),
    );

    late FakeActivityMapRepository repository;

    Future<ActivitiesMapViewModel> pumpWithBackend(WidgetTester tester) async {
      repository = FakeActivityMapRepository()..activities = [concert];
      final mapViewModel = ActivitiesMapViewModel(repository: repository);
      addTearDown(mapViewModel.dispose);
      await pumpInici(tester, mapViewModel: mapViewModel);
      await openMap(tester);
      return mapViewModel;
    }

    testWidgets('El mapa mostra les activitats de la zona i obre la fitxa', (
      tester,
    ) async {
      final mapViewModel = await pumpWithBackend(tester);
      // Ho fa el mapa en obrir-se i en moure'l; a les proves no hi ha mapa.
      await mapViewModel.loadArea(area);
      await tester.pumpAndSettle();

      // Les de la zona, no les de demostració de la llista.
      expect(map(tester).markers.map((m) => m.markerId.value), ['1282']);

      marker(tester, '1282').onTap!();
      await tester.pumpAndSettle();
      expect(find.text('Font: Agenda Cultural · Generalitat'), findsOneWidget);

      await tester.tap(find.text('Font: Agenda Cultural · Generalitat'));
      expect(openedFromMap, ['1282']);
      expect(opened, isEmpty);
    });

    testWidgets('Si la zona no es pot carregar, es pot tornar a provar', (
      tester,
    ) async {
      final mapViewModel = await pumpWithBackend(tester);
      repository.loadArea = (_) => Future.error(Exception('sense xarxa'));
      await mapViewModel.loadArea(area);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No hem pogut carregar les activitats d’aquesta zona. '
          'Torna-ho a provar.',
        ),
        findsOneWidget,
      );
      expect(map(tester).markers, isEmpty);

      repository.loadArea = null;
      await tester.tap(find.text('Tornar-ho a provar'));
      await tester.pumpAndSettle();

      expect(find.text('Tornar-ho a provar'), findsNothing);
      expect(map(tester).markers.map((m) => m.markerId.value), ['1282']);
    });
  });

  test('El tipus de marcador depèn de la font i de l’amistat', () {
    Activity community({required bool friend}) => Activity(
      id: 'c',
      title: 'C',
      category: 'Teatre',
      municipality: 'Vic',
      startsAt: DateTime(2026, 11, 1),
      imageAsset: 'a.jpg',
      source: ActivitySource.community,
      location: cataloniaCenter,
      creator: ActivityCreator(name: 'Pol', isFriend: friend),
    );

    expect(
      activityMarkerKind(community(friend: false)),
      ActivityMarkerKind.community,
    );
    expect(
      activityMarkerKind(community(friend: true)),
      ActivityMarkerKind.friend,
    );
  });
}
