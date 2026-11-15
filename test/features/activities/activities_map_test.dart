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
    expect(map(tester).clusterManagers, hasLength(1));
    for (final m in map(tester).markers) {
      expect(
        m.clusterManagerId,
        map(tester).clusterManagers.single.clusterManagerId,
      );
    }

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

    await tester.tap(find.byTooltip('Tancar'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tancar'), findsNothing);
    // En tancar-la, els botons tornen a baix.
    expect(overlays.last, 0);
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

  group('Tocar un grup', () {
    const clusterId = ClusterManagerId('activities');

    Cluster cluster(List<String> ids, LatLngBounds bounds) => Cluster(
      clusterId,
      [for (final id in ids) MarkerId(id)],
      position: bounds.northeast,
      bounds: bounds,
    );

    void tapCluster(WidgetTester tester, Cluster tapped) =>
        map(tester).clusterManagers.single.onClusterTap!(tapped);

    testWidgets(
      'Si són al mateix lloc, en mostra la llista per data i obre la fitxa',
      (tester) async {
        await pumpInici(tester);
        await openMap(tester);

        // Teatre sota les estrelles (diumenge) i Jazz al parc (dissabte).
        tapCluster(
          tester,
          cluster(
            ['demo-theatre', 'demo-jazz'],
            LatLngBounds(
              southwest: const LatLng(41.38810, 2.18740),
              northeast: const LatLng(41.38812, 2.18742),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('2 activitats en aquest lloc'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('Jazz al parc').last).dy,
          lessThan(
            tester.getTopLeft(find.text('Teatre sota les estrelles')).dy,
          ),
        );

        await tester.tap(find.text('Teatre sota les estrelles'));
        await tester.pumpAndSettle();
        expect(opened, ['demo-theatre']);
        expect(find.text('2 activitats en aquest lloc'), findsNothing);
      },
    );

    testWidgets('Si són escampats, no obre cap llista i tanca la targeta', (
      tester,
    ) async {
      await pumpInici(tester);
      await openMap(tester);
      marker(tester, 'demo-jazz').onTap!();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tancar'), findsOneWidget);

      // Barcelona i Tarragona: s'hi apropa el mapa (a les proves no n'hi ha).
      tapCluster(
        tester,
        cluster(
          ['demo-jazz', 'demo-theatre'],
          LatLngBounds(
            southwest: const LatLng(41.1146, 1.2593),
            northeast: const LatLng(41.3881, 2.1874),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('activitats en aquest lloc'), findsNothing);
      expect(find.byTooltip('Tancar'), findsNothing);
    });
  });

  testWidgets(
    'Un marcador amb altres al mateix lloc mostra la llista, no la targeta',
    (tester) async {
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
      await pumpInici(
        tester,
        activities: [
          at('cor', 'Cor Maragall', auditori, 8),
          at('orgue', 'Concert d’orgue', auditori, 7),
          at('lluny', 'Lluny d’aquí', cataloniaCenter, 9),
        ],
      );
      await openMap(tester);

      // Molt a prop, Google no els agrupa: només es pot tocar el de dalt.
      marker(tester, 'cor').onTap!();
      await tester.pumpAndSettle();
      expect(find.text('2 activitats en aquest lloc'), findsOneWidget);
      expect(find.byTooltip('Tancar'), findsNothing);
      await tester.tap(find.text('Concert d’orgue'));
      await tester.pumpAndSettle();
      expect(opened, ['orgue']);

      // Un marcador sol continua mostrant la seva targeta.
      marker(tester, 'lluny').onTap!();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tancar'), findsOneWidget);
    },
  );

  test('Uns metres de diferència són el mateix lloc; uns carrers, no', () {
    LatLngBounds around(double degrees) => LatLngBounds(
      southwest: const LatLng(41.3881, 2.1874),
      northeast: LatLng(41.3881 + degrees, 2.1874 + degrees),
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
