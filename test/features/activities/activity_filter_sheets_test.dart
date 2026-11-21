import 'dart:async';
import 'dart:convert';
import 'dart:ui' show SemanticsAction;

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/data/http_activity_map_repository.dart';
import 'package:aprop/features/activities/data/http_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/activity_filters.dart';
import 'package:aprop/features/activities/models/geo_bounds.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/presentation/screens/activities_screen.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_map_view_model.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_view_model.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:aprop/features/activities/presentation/widgets/map_filter_bar.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_categories_filter_sheet.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_date_filter_sheet.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_filter_calendar.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_filter_feedback.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_activity_map_repository.dart';
import 'fake_activity_repository.dart';
import 'fake_enrollment_repository.dart';
import 'activity_filter_test_data.dart';
import 'backend_event_fixture.dart';

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
    // La fila de xips es desplaça de costat: amb la lletra gran, potser cal.
    final chip = find.byKey(ValueKey('activities-filter-$filter'));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
  }

  GoogleMap map(WidgetTester tester) => tester.widget(find.byType(GoogleMap));

  testWidgets(
    'Categories load from the repository, with retry and draft selection',
    (tester) async {
      final pending = Completer<List<String>>();
      final repository = FakeActivityRepository()
        ..onCategories = () => pending.future;
      model.dispose();
      model = ActivitiesViewModel(repository: repository);
      await pumpScreen(tester);
      await tester.tap(
        find.byKey(const ValueKey('activities-filter-categories')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Aplicar'))
            .onPressed,
        isNull,
      );
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(
        find.text('No hem pogut carregar les categories.'),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsNothing);
      repository.onCategories = () async => ['Concerts', 'Teatre'];
      await tester.tap(find.text('Tornar-ho a provar'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      await tester.tap(category('Concerts'));
      expect(model.filters.isActive, isFalse);
      await apply(tester);
      expect(model.filters.categories, {'Concerts'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'An empty category catalogue keeps the unrestricted option usable',
    (tester) async {
      model.dispose();
      model = ActivitiesViewModel(
        repository: FakeActivityRepository()..onCategories = () async => [],
      );
      await pumpScreen(tester);
      await open(tester, 'categories');
      expect(
        find.text(
          'No hi ha categories disponibles. Pots consultar totes les activitats.',
        ),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsNothing);
      await apply(tester);
      expect(model.filters.isActive, isFalse);
      expect(find.byType(ActivityCategoriesFilterSheet), findsNothing);
    },
  );

  testWidgets('An empty category catalogue offers a retry in the same panel', (
    tester,
  ) async {
    var requests = 0;
    model.dispose();
    model = ActivitiesViewModel(
      repository: FakeActivityRepository()
        ..onCategories = () async => ++requests == 1 ? [] : ['Teatre'],
    );
    await pumpScreen(tester);
    await open(tester, 'categories');
    expect(find.byType(CheckboxListTile), findsNothing);

    await tester.tap(find.text('Tornar-ho a provar'));
    await tester.pumpAndSettle();
    expect(category('Teatre'), findsOneWidget);
    expect(requests, 2);
    await tester.tap(category('Teatre'));
    await apply(tester);
    expect(model.filters.categories, {'Teatre'});
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'The map shows valid HTTP categories when the catalogue contains unnamed rows',
    (tester) async {
      final requestedIds = <String?>[];
      final repository = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((request) async {
            final Object body;
            if (request.url.path == '/categories') {
              body = [
                {'id': 1, 'name': ''},
                {'id': 3, 'name': 'agenda:categories/teatre'},
                {'id': 4, 'name': 'agenda:ambits/concerts'},
              ];
            } else {
              requestedIds.add(request.url.queryParameters['filterCategory']);
              body = [];
            }
            return http.Response.bytes(
              utf8.encode(jsonEncode(body)),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      model.dispose();
      model = ActivitiesViewModel(repository: repository);
      await pumpScreen(tester);
      await open(tester, 'categories');
      expect(category('Concerts'), findsOneWidget);
      expect(category('Teatre'), findsOneWidget);
      expect(find.text('No hem pogut carregar les categories.'), findsNothing);

      await tester.tap(category('Teatre'));
      await apply(tester);
      expect(model.filters.categories, {'Teatre'});
      expect(requestedIds.last, '3');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'HTTP map badges and secondary-category filters stay consistent with the list',
    (tester) async {
      final paths = <String>[];
      final filterIds = <String?>[];
      final events = [
        {
          ...backendEvent(1),
          'categories': [
            'agenda:categories/',
            'agenda:categories/musica',
            'agenda:ambits/concerts',
          ],
          'latitude': 41.98,
          'longitude': 2.82,
        },
        {
          ...backendEvent(2),
          'categories': ['agenda:categories/teatre'],
          'latitude': 41.12,
          'longitude': 1.24,
        },
      ];
      final client = ApiClient(
        client: MockClient((request) async {
          paths.add(request.url.path);
          final Object body;
          switch (request.url.path) {
            case '/categories':
              body = [
                {'id': 1, 'name': ''},
                {'id': 3, 'name': 'agenda:categories/musica'},
                {'id': 4, 'name': 'agenda:ambits/concerts'},
                {'id': 5, 'name': 'agenda:categories/teatre'},
              ];
            case '/events/map':
              body = events;
            case '/events':
              final id = request.url.queryParameters['filterCategory'];
              filterIds.add(id);
              body = id == '4' ? [events.first] : events;
            default:
              throw StateError('Unexpected request: ${request.url.path}');
          }
          return http.Response.bytes(
            utf8.encode(jsonEncode(body)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      model.dispose();
      model = ActivitiesViewModel(
        repository: HttpActivityRepository(apiClient: client),
      );
      final areaModel = ActivitiesMapViewModel(
        repository: HttpActivityMapRepository(apiClient: client),
      );
      addTearDown(areaModel.dispose);
      await areaModel.loadArea(
        const GeoBounds(
          southWest: GeoPoint(latitude: 40, longitude: 0),
          northEast: GeoPoint(latitude: 43, longitude: 4),
        ),
      );
      await pumpScreen(tester, areaModel: areaModel);
      expect(
        map(tester).markers.map((marker) => marker.markerId.value),
        unorderedEquals(['1', '2']),
      );
      map(tester).markers
          .singleWhere((marker) => marker.markerId.value == '1')
          .onTap!();
      await tester.pumpAndSettle();
      expect(find.text('Música'), findsOneWidget);

      await open(tester, 'categories');
      await tester.tap(category('Concerts'));
      await apply(tester);
      expect(map(tester).markers.single.markerId.value, '1');
      // With the Concerts filter active, the map card surfaces Concerts first.
      map(tester).markers.single.onTap!();
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(Card), matching: find.text('Concerts')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(Card), matching: find.text('+1')),
        findsOneWidget,
      );
      expect(find.byType(MapFilterFeedback), findsNothing);
      expect(model.filters.categories, {'Concerts'});
      expect(filterIds, [null, '4']);
      expect(map(tester).markers.single.markerId.value, '1');
      expect(paths.where((path) => path == '/events/map'), hasLength(1));
      expect(paths.where((path) => path == '/categories'), hasLength(1));
      expect(
        paths.any((path) => RegExp(r'^/events/\d+$').hasMatch(path)),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Missing map categories show a notice, not a false empty result',
    (tester) async {
      final areaModel = ActivitiesMapViewModel(
        repository: FakeActivityMapRepository()
          ..activities = [
            event('unknown', DateTime(2026, 9, 26), category: 'Activitat'),
          ],
      );
      addTearDown(areaModel.dispose);
      await areaModel.loadArea(
        const GeoBounds(
          southWest: GeoPoint(latitude: 41, longitude: 1),
          northEast: GeoPoint(latitude: 42, longitude: 3),
        ),
      );
      await pumpScreen(tester, areaModel: areaModel);
      await open(tester, 'categories');
      await tester.tap(category('Música'));
      await apply(tester);
      expect(
        find.text('No hi ha activitats amb aquests filtres en aquesta zona.'),
        findsNothing,
      );
      // Sense llista (#274), només s'avisa de les que no s'hi inclouen.
      expect(
        find.text(
          '1 activitat sense categoria informada no s’inclou en aquest filtre.',
        ),
        findsOneWidget,
      );
      expect(find.text('Veure llista'), findsNothing);
      expect(model.filters.categories, {'Música'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Category edits remain a draft until Apply and filter the map', (
    tester,
  ) async {
    await pumpScreen(tester);
    await open(tester, 'categories');
    expect(find.byType(CheckboxListTile), findsNWidgets(8));
    expect(category('Cultura popular').hitTestable(), findsOneWidget);
    await tester.tap(category('Música'));
    await tester.tap(category('Teatre'));
    await tester.pumpAndSettle();
    expect(find.text('2 categories seleccionades'), findsOneWidget);
    expect(model.activities.length, 3);
    final chip = find.byKey(const ValueKey('activities-filter-categories'));
    expect(
      find.descendant(of: chip, matching: find.text('Categories')),
      findsOneWidget,
    );
    await apply(tester);
    expect(model.activities.map((a) => a.id), ['demo-jazz', 'demo-theatre']);
    // El xip mostra les categories triades en lloc del nom del filtre.
    expect(
      find.descendant(of: chip, matching: find.text('Categories')),
      findsNothing,
    );
    expect(
      map(tester).markers.map((m) => m.markerId.value),
      unorderedEquals(['demo-jazz', 'demo-theatre']),
    );
    expect(model.filters.categories, {'Música', 'Teatre'});
  });

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
    expect(find.byType(MapFilterBar), findsOneWidget);
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
        find.textContaining('No hi ha activitats amb aquests filtres'),
        findsOneWidget,
      );
      await tester.tap(find.text('Netejar filtres'));
      await tester.pumpAndSettle();
      expect(model.activities.length, 3);
    },
  );

  testWidgets(
    'Map groups contain only activities kept by the confirmed filters',
    (tester) async {
      await pumpScreen(tester);

      // Far away, Barcelona, Tarragona and Girona overlap and make one
      // group of three.
      map(tester).onCameraMove!(
        const CameraPosition(target: LatLng(41.5, 1.8), zoom: 3),
      );
      map(tester).onCameraIdle!();
      await tester.pumpAndSettle();
      final unfiltered = map(tester).markers.single.markerId.value;
      expect(unfiltered, startsWith('grup:'));
      expect(unfiltered, endsWith(':3'));

      // With the same zoom, the exhibition in Girona, filtered out, is no
      // longer counted in the group.
      await open(tester, 'categories');
      await tester.tap(category('Música'));
      await tester.tap(category('Teatre'));
      await apply(tester);
      expect(map(tester).markers.map((marker) => marker.markerId.value), [
        'grup:demo-jazz:2',
      ]);
      expect(model.filters.categories, {'Música', 'Teatre'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Filtering out a selected marker closes its card and resets the overlay',
    (tester) async {
      await pumpScreen(tester);
      map(tester).markers
          .singleWhere((m) => m.markerId.value == 'demo-theatre')
          .onTap!();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tancar'), findsOneWidget);
      expect(overlays.last, greaterThan(0));
      await open(tester, 'categories');
      await tester.tap(category('Música'));
      await apply(tester);
      expect(find.byTooltip('Tancar'), findsNothing);
      expect(overlays.last, 0);
      await tester.tap(find.byTooltip('Netejar tots els filtres'));
      await tester.pumpAndSettle();
      expect(map(tester).markers, hasLength(3));
      expect(find.byTooltip('Tancar'), findsNothing);
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
          // Lluny de Barcelona perquè no s'agrupin al mapa.
          location: const GeoPoint(latitude: 41.9, longitude: 1.2),
        ),
      ];
      await pumpScreen(tester, areaModel: areaModel);
      await open(tester, 'categories');
      await tester.tap(category('Música'));
      await apply(tester);
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
      model = ActivitiesViewModel(repository: FakeActivityRepository());
      await model.applyFilters(ActivityFilters(categories: ['Cinema']));
      final areaModel = ActivitiesMapViewModel(
        repository: FakeActivityMapRepository()
          ..activities = [
            event('unknown', DateTime(2026, 9, 26), category: 'Activitat'),
          ],
      );
      addTearDown(areaModel.dispose);
      await areaModel.loadArea(
        const GeoBounds(
          southWest: GeoPoint(latitude: 41, longitude: 1),
          northEast: GeoPoint(latitude: 42, longitude: 3),
        ),
      );
      await pumpScreen(tester, scale: 2, areaModel: areaModel);
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
      final clear = find.text('Netejar filtres');
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      await tester.tap(clear);
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

  testWidgets(
    'Category filter sheet localizes and sorts labels cleanly in es and en',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(
            body: ActivityCategoriesFilterSheet(
              initialCategories: {'Espectacles'},
              categories: [
                'agenda:ambits/zz-altres-ambits',
                'agenda:ambits/espectacles',
                'agenda:categories/any-gaudi',
                'agenda:categories/musica',
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gaudí Year'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Other fields'), findsOneWidget);
      expect(find.text('Performing arts'), findsOneWidget);
      expect(find.textContaining('Zz'), findsNothing);
      final performingArtsTile = tester.widget<CheckboxListTile>(
        find.byKey(const ValueKey('activity-filter-category-Performing arts')),
      );
      expect(performingArtsTile.value, isTrue);
    },
  );
}
