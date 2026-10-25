import 'dart:ui' show SemanticsAction;

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/activity_filters.dart';
import 'package:aprop/features/activities/models/geo_bounds.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/presentation/screens/activities_screen.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_map_view_model.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_view_model.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:aprop/features/activities/presentation/widgets/activities_header.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_categories_filter_sheet.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_date_filter_sheet.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_filter_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'fake_activity_map_repository.dart';
import 'fake_activity_repository.dart';
import 'fake_enrollment_repository.dart';
import 'activity_filter_test_data.dart';

void main() {
  late ActivitiesViewModel model;
  late EnrollmentViewModel enrollments;
  late List<double> overlays;

  setUp(() {
    model = ActivitiesViewModel(repository: DemoActivityRepository());
    enrollments = EnrollmentViewModel(
      userId: 'user',
      repository: FakeEnrollmentRepository(),
    )..load();
    overlays = [];
  });
  tearDown(() {
    model.dispose();
    enrollments.dispose();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    double scale = 1,
    ActivitiesMapViewModel? areaModel,
  }) async {
    tester.view.physicalSize = Size(
      scale > 1 ? 320 : 390,
      scale > 1 ? 700 : 844,
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await model.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: ActivitiesScreen(
            viewModel: model,
            enrollmentViewModel: enrollments,
            onActivitySelected: (_) {},
            onMapOverlayChanged: overlays.add,
            mapViewModel: areaModel,
            now: () => DateTime(2026, 9, 25, 18),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder category(String label) =>
      find.byKey(ValueKey('activity-filter-category-$label'));
  Finder date(int day, {int month = 9}) =>
      find.byKey(ValueKey('activity-filter-date-2026-$month-$day'));
  Finder getSheetScroll() => find.descendant(
    of: find.byKey(const ValueKey('activity-filter-scroll')),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  Future<void> open(WidgetTester tester, String filter) async {
    await tester.tap(find.byKey(ValueKey('activities-filter-$filter')));
    await tester.pumpAndSettle();
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
  }

  GoogleMap map(WidgetTester tester) => tester.widget(find.byType(GoogleMap));

  testWidgets(
    'Category edits remain a draft until Apply and appear in both views',
    (tester) async {
      await pumpScreen(tester);
      await open(tester, 'categories');
      expect(find.byType(CheckboxListTile), findsNWidgets(8));
      expect(category('Cultura popular').hitTestable(), findsOneWidget);
      await tester.tap(category('Música'));
      await tester.tap(category('Teatre'));
      await tester.pumpAndSettle();
      expect(find.text('2 categories seleccionades'), findsOneWidget);
      expect(model.activities.length, 3);
      expect(
        tester
            .widget<ActivitiesHeader>(find.byType(ActivitiesHeader))
            .categoriesSelected,
        isFalse,
      );
      await apply(tester);
      expect(model.activities.map((a) => a.id), ['demo-jazz', 'demo-theatre']);
      expect(
        tester
            .widget<ActivitiesHeader>(find.byType(ActivitiesHeader))
            .categoriesSelected,
        isTrue,
      );
      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();
      expect(
        map(tester).markers.map((m) => m.markerId.value),
        unorderedEquals(['demo-jazz', 'demo-theatre']),
      );
      await tester.tap(find.text('Llista'));
      await tester.pumpAndSettle();
      expect(model.filters.categories, {'Música', 'Teatre'});
    },
  );

  testWidgets(
    'A new filter resets an unmounted list; switching views alone preserves it',
    (tester) async {
      model.dispose();
      model = ActivitiesViewModel(
        repository: FakeActivityRepository()
          ..activities = List.generate(
            20,
            (index) => event(
              'activity-$index',
              DateTime(2026, 9, 26),
              category: index.isEven ? 'Música' : 'Teatre',
            ),
          ),
      );
      await pumpScreen(tester);
      final list = find.byKey(const PageStorageKey<String>('activities-list'));
      double offset() => tester.widget<ListView>(list).controller!.offset;
      await tester.drag(list, const Offset(0, -500));
      await tester.pumpAndSettle();
      final previous = offset();
      expect(previous, greaterThan(0));
      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Llista'));
      await tester.pumpAndSettle();
      expect(offset(), previous);
      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();
      await open(tester, 'categories');
      await tester.tap(category('Música'));
      await apply(tester);
      await tester.tap(find.text('Llista'));
      await tester.pumpAndSettle();
      expect(offset(), 0);
      expect(find.text('activity-0').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A repeated confirmation does not pop the underlying app route', (
    tester,
  ) async {
    await pumpScreen(tester);
    await open(tester, 'categories');
    await tester.tap(category('Música'));
    await tester.pumpAndSettle();
    final confirm = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Aplicar'))
        .onPressed!;
    confirm();
    confirm();
    await tester.pumpAndSettle();
    expect(find.byType(ActivitiesHeader), findsOneWidget);
    expect(model.filters.categories, {'Música'});
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Clear is provisional; applying it removes only the edited filter',
    (tester) async {
      final initial = ActivityFilters(
        dates: ActivityDateRange(start: DateTime(2026, 9, 26)),
        categories: ['Música'],
      );
      model.applyFilters(initial);
      await pumpScreen(tester);
      await open(tester, 'categories');
      await tester.tap(find.text('Netejar'));
      await tester.tap(find.byTooltip('Tancar el filtre'));
      await tester.pumpAndSettle();
      expect(model.filters, initial);
      await open(tester, 'categories');
      await tester.tap(find.text('Netejar'));
      await apply(tester);
      expect(model.filters.categories, isEmpty);
      expect(model.filters.dates, initial.dates);
      await open(tester, 'dates');
      await tester.tap(find.text('Netejar'));
      await apply(tester);
      expect(model.filters.isActive, isFalse);
      expect(model.activities.length, 3);
    },
  );

  for (final dismissal in ['back', 'barrier']) {
    testWidgets('$dismissal discards a changed date draft', (tester) async {
      await pumpScreen(tester);
      await open(tester, 'dates');
      await tester.tap(find.text('Demà'));
      await tester.pumpAndSettle();
      if (dismissal == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tapAt(const Offset(8, 8));
      }
      await tester.pumpAndSettle();
      expect(find.byType(ActivityDateFilterSheet), findsNothing);
      expect(model.filters.isActive, isFalse);
    });
  }

  testWidgets(
    'Calendar and presets agree; manual ranges span months and sort endpoints',
    (tester) async {
      await pumpScreen(tester);
      await open(tester, 'dates');
      expect(find.text('Setembre 2026'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'activity-filter-date-',
              ),
        ),
        findsNWidgets(30),
      );
      await tester.tap(find.text('Aquest cap de setmana'));
      await tester.pumpAndSettle();
      var calendar = tester.widget<ActivityFilterCalendar>(
        find.byType(ActivityFilterCalendar),
      );
      expect(calendar.selectedRange!.start, DateTime(2026, 9, 26));
      expect(calendar.selectedRange!.end, DateTime(2026, 9, 27));
      expect(model.filters.dates, isNull);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(
          tester
              .getSemantics(date(26))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
      } finally {
        semantics.dispose();
      }
      await tester.tap(date(29));
      await tester.tap(date(26));
      await tester.pumpAndSettle();
      calendar = tester.widget(find.byType(ActivityFilterCalendar));
      expect(calendar.selectedRange!.start, DateTime(2026, 9, 26));
      expect(calendar.selectedRange!.end, DateTime(2026, 9, 29));
      await tester.tap(date(30));
      await tester.tap(find.byTooltip('Mes següent'));
      await tester.pumpAndSettle();
      await tester.tap(date(2, month: 10));
      await apply(tester);
      expect(model.filters.dates!.start, DateTime(2026, 9, 30));
      expect(model.filters.dates!.end, DateTime(2026, 10, 2));
      expect(
        find.text('No hi ha activitats amb aquests filtres'),
        findsOneWidget,
      );
      await tester.tap(find.text('Netejar filtres'));
      await tester.pumpAndSettle();
      expect(model.activities.length, 3);
    },
  );

  testWidgets(
    'Cluster sheets contain only activities kept by the confirmed filters',
    (tester) async {
      await pumpScreen(tester);
      await open(tester, 'categories');
      await tester.tap(category('Música'));
      await tester.tap(category('Teatre'));
      await apply(tester);
      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();

      final filteredMap = map(tester);
      filteredMap.clusterManagers.single.onClusterTap!(
        Cluster(
          filteredMap.clusterManagers.single.clusterManagerId,
          filteredMap.markers.map((marker) => marker.markerId).toList(),
          position: const LatLng(41.38812, 2.18742),
          bounds: LatLngBounds(
            southwest: const LatLng(41.38810, 2.18740),
            northeast: const LatLng(41.38812, 2.18742),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 activitats en aquest lloc'), findsOneWidget);
      expect(find.text('Jazz al parc'), findsOneWidget);
      expect(find.text('Teatre sota les estrelles'), findsOneWidget);
      expect(find.text('Mirades de Catalunya'), findsNothing);
      await tester.tap(find.text('Teatre sota les estrelles'));
      await tester.pumpAndSettle();
      expect(find.text('2 activitats en aquest lloc'), findsNothing);
      expect(model.filters.categories, {'Música', 'Teatre'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Filtering out a selected marker closes its card and resets the overlay',
    (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();
      map(tester).markers
          .singleWhere((m) => m.markerId.value == 'demo-theatre')
          .onTap!();
      await tester.pumpAndSettle();
      expect(find.text('Veure activitat'), findsOneWidget);
      expect(overlays.last, greaterThan(0));
      await open(tester, 'categories');
      await tester.tap(category('Música'));
      await apply(tester);
      expect(find.text('Veure activitat'), findsNothing);
      expect(overlays.last, 0);
      await tester.tap(find.byTooltip('Netejar tots els filtres'));
      await tester.pumpAndSettle();
      expect(map(tester).markers, hasLength(3));
      expect(find.text('Veure activitat'), findsNothing);
    },
  );

  testWidgets(
    'Incoming map results use current filters without another area request',
    (tester) async {
      final repository = FakeActivityMapRepository();
      final areaModel = ActivitiesMapViewModel(repository: repository);
      addTearDown(areaModel.dispose);
      final jazz = (await DemoActivityRepository().getActivities()).first;
      repository.activities = [
        jazz,
        Activity(
          id: 'unknown',
          title: 'Sense categoria',
          category: 'Activitat',
          municipality: 'Barcelona',
          startsAt: DateTime(2026, 9, 26),
          imageAsset: '',
          source: ActivitySource.culturalAgenda,
          location: const GeoPoint(latitude: 41.4, longitude: 2.1),
        ),
      ];
      await pumpScreen(tester, areaModel: areaModel);
      await open(tester, 'categories');
      await tester.tap(category('Música'));
      await apply(tester);
      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();
      await areaModel.loadArea(
        const GeoBounds(
          southWest: GeoPoint(latitude: 41, longitude: 1),
          northEast: GeoPoint(latitude: 42, longitude: 3),
        ),
      );
      await tester.pumpAndSettle();
      expect(map(tester).markers.map((m) => m.markerId.value), ['demo-jazz']);
      expect(
        find.text(
          '1 activitat sense categoria informada no s’inclou en aquest filtre.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Netejar tots els filtres'));
      await tester.pumpAndSettle();
      expect(map(tester).markers.length, 2);
      expect(repository.requestedAreas.length, 1);
    },
  );

  testWidgets(
    'Map feedback stays scrollable with narrow screens and doubled text',
    (tester) async {
      model.dispose();
      model = ActivitiesViewModel(
        repository: FakeActivityRepository()
          ..activities = [
            event('unknown', DateTime(2026, 9, 26), category: 'Activitat'),
          ],
      )..applyFilters(ActivityFilters(categories: ['Cinema']));
      await pumpScreen(tester, scale: 2);
      await tester.ensureVisible(find.text('Mapa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();
      final message = find.text(
        '1 activitat sense categoria informada no s’inclou en aquest filtre.',
      );
      final viewport = find.byKey(
        const ValueKey('activity-map-filter-feedback'),
      );
      await tester.drag(viewport, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(message).dy,
        lessThanOrEqualTo(tester.getBottomRight(viewport).dy),
      );
      await tester.ensureVisible(find.text('Netejar filtres'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Netejar filtres'));
      await tester.pumpAndSettle();
      expect(model.filters.isActive, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Panels tolerate narrow screens and doubled text with fixed actions',
    (tester) async {
      await pumpScreen(tester, scale: 2);
      await open(tester, 'categories');
      await tester.scrollUntilVisible(
        category('Cultura popular'),
        180,
        scrollable: getSheetScroll(),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(category('Cultura popular'));
      await tester.pumpAndSettle();
      await tester.tap(category('Cultura popular'));
      await tester.pumpAndSettle();
      expect(find.text('Aplicar').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await apply(tester);
      await open(tester, 'dates');
      await tester.scrollUntilVisible(
        date(26),
        180,
        scrollable: getSheetScroll(),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(date(26));
      await tester.pumpAndSettle();
      await tester.tap(date(26));
      await tester.pumpAndSettle();
      expect(find.text('Aplicar').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await apply(tester);
      expect(model.filters.categories, {'Cultura popular'});
      expect(model.filters.dates!.start, DateTime(2026, 9, 26));
    },
  );

  testWidgets('Disposing the owning screen removes its root filter modal', (
    tester,
  ) async {
    await pumpScreen(tester);
    await open(tester, 'categories');
    await tester.tap(category('Música'));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Text('Signed out')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Signed out'), findsOneWidget);
    expect(find.byType(ActivityCategoriesFilterSheet), findsNothing);
    expect(model.filters.isActive, isFalse);
    expect(tester.takeException(), isNull);
  });
}
