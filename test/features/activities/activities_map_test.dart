import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/presentation/screens/activities_screen.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_view_model.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:aprop/features/activities/presentation/widgets/activities_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'fake_activity_repository.dart';
import 'fake_enrollment_repository.dart';

void main() {
  late List<String> opened;
  late List<double> overlays;

  Future<void> pumpInici(
    WidgetTester tester, {
    List<Activity>? activities,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    opened = [];
    overlays = [];

    final repository = activities == null
        ? DemoActivityRepository()
        : (FakeActivityRepository()..activities = activities);
    final viewModel = ActivitiesViewModel(repository: repository)..load();
    final enrollments = EnrollmentViewModel(
      userId: 'test-user',
      repository: FakeEnrollmentRepository(),
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

  testWidgets('Tocar un marcador mostra la targeta i «Veure activitat»', (
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

    await tester.tap(find.text('Veure activitat'));
    expect(opened, ['demo-theatre']);

    await tester.tap(find.byTooltip('Tancar'));
    await tester.pumpAndSettle();
    expect(find.text('Veure activitat'), findsNothing);
    // En tancar-la, els botons tornen a baix.
    expect(overlays.last, 0);
  });

  testWidgets('Tocar el mapa tanca la targeta', (tester) async {
    await pumpInici(tester);
    await openMap(tester);

    marker(tester, 'demo-jazz').onTap!();
    await tester.pumpAndSettle();
    expect(find.text('Veure activitat'), findsOneWidget);

    map(tester).onTap!(const LatLng(41.5, 2.0));
    await tester.pumpAndSettle();
    expect(find.text('Veure activitat'), findsNothing);
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
