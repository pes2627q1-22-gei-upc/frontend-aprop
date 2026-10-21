import 'dart:async';

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/discovery_feed.dart';
import 'package:aprop/features/activities/presentation/screens/activity_search_screen.dart';
import 'package:aprop/features/activities/presentation/screens/discover_screen.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_discovery_repository.dart';
import 'fake_enrollment_repository.dart';

void main() {
  late FakeDiscoveryRepository repository;
  late FakeEnrollmentRepository enrollments;
  late EnrollmentViewModel enrollment;
  late List<Activity> activities;
  String? opened;
  var searchOpened = 0;

  setUp(() async {
    repository = FakeDiscoveryRepository();
    activities = await DemoActivityRepository().getActivities();
    repository.feed = DiscoveryFeed(
      recommended: [activities[1]],
      featured: [activities[2]],
    );
    repository.results = [activities[2]];
    enrollments = FakeEnrollmentRepository();
    enrollment = EnrollmentViewModel(userId: 'user', repository: enrollments);
    await enrollment.load();
    opened = null;
    searchOpened = 0;
  });
  tearDown(() async {
    enrollment.dispose();
    await enrollments.dispose();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool search = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: search
            ? ActivitySearchScreen(
                repository: repository,
                enrollmentViewModel: enrollment,
                onActivitySelected: (id) => opened = id,
                onBack: () {},
              )
            : Scaffold(
                appBar: AppBar(title: const Text('Descobreix')),
                body: DiscoverScreen(
                  userId: 'user',
                  repository: repository,
                  enrollmentViewModel: enrollment,
                  onSearchPressed: () => searchOpened++,
                  onActivitySelected: (id) => opened = id,
                ),
              ),
      ),
    );
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Feed exposes search, reusable cards and a truthful fallback subtitle',
    (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();
      expect(find.text('Per a tu'), findsOneWidget);
      expect(find.text('Una selecció per començar'), findsOneWidget);
      expect(find.text('Segons els teus interessos'), findsNothing);
      expect(find.text('Assistent'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('discover-search')));
      expect(searchOpened, 1);
      await tester.tap(find.text('Mirades de Catalunya'));
      expect(opened, 'demo-exhibition');
      expect(enrollments.enrolledRequests, isEmpty);
    },
  );

  testWidgets(
    'Feed enrollment waits for confirmation without opening the detail',
    (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();
      final pending = Completer<void>();
      enrollments.onEnroll = (_, _) => pending.future;
      final card = find.byKey(
        const ValueKey('discover-recommended-demo-exhibition'),
      );
      final button = find.descendant(
        of: card,
        matching: find.text('M’hi apunto'),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(find.text('Apuntant…'), findsOneWidget);
      expect(find.text('Apuntat'), findsNothing);
      expect(opened, isNull);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Apuntat'), findsOneWidget);
      expect(enrollments.enrolledRequests, ['user/demo-exhibition']);
    },
  );

  testWidgets(
    'Feed handles loading, error, retry and a successful empty response',
    (tester) async {
      final pending = Completer<DiscoveryFeed>();
      repository.onFeed = (_) => pending.future;
      await pumpScreen(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Encara no hi ha propostes'), findsNothing);
      pending.completeError(StateError('Offline'));
      await tester.pumpAndSettle();
      expect(find.text('Tornar-ho a provar'), findsOneWidget);
      repository.onFeed = (_) async =>
          DiscoveryFeed(recommended: [], featured: []);
      await tester.tap(find.text('Tornar-ho a provar'));
      await tester.pumpAndSettle();
      expect(find.text('Encara no hi ha propostes'), findsOneWidget);
      expect(find.byKey(const ValueKey('discover-search')), findsOneWidget);
    },
  );

  testWidgets('Search starts empty and people remains visibly unavailable', (
    tester,
  ) async {
    await pumpScreen(tester, search: true);
    await tester.pumpAndSettle();
    expect(find.text('Quina activitat busques?'), findsOneWidget);
    expect(repository.queries, isEmpty);
    final segmented = tester.widget<SegmentedButton<bool>>(
      find.byType(SegmentedButton<bool>),
    );
    expect(segmented.segments.last.enabled, isFalse);
    expect(segmented.selected, {true});
  });

  testWidgets(
    'Search submits, counts results and clears back to the initial state',
    (tester) async {
      await pumpScreen(tester, search: true);
      await submit(tester, 'teatre');
      expect(repository.queries, ['teatre']);
      expect(find.text('1 activitat trobada'), findsOneWidget);
      await tester.tap(find.text('Teatre sota les estrelles'));
      expect(opened, 'demo-theatre');
      await tester.tap(find.byTooltip('Esborrar la cerca'));
      await tester.pumpAndSettle();
      expect(find.text('Quina activitat busques?'), findsOneWidget);
      expect(find.text('Teatre sota les estrelles'), findsNothing);
      expect(repository.queries, ['teatre']);
    },
  );

  testWidgets(
    'Search distinguishes a pending request, an error and zero matches',
    (tester) async {
      final pending = Completer<List<Activity>>();
      repository.onSearch = (_) => pending.future;
      await pumpScreen(tester, search: true);
      await tester.enterText(find.byType(TextField), 'teatre');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No hem trobat activitats'), findsNothing);
      pending.completeError(StateError('Offline'));
      await tester.pumpAndSettle();
      expect(find.text('Tornar-ho a provar'), findsOneWidget);
      repository.onSearch = (_) async => [];
      await tester.tap(find.text('Tornar-ho a provar'));
      await tester.pumpAndSettle();
      expect(find.text('0 activitats trobades'), findsOneWidget);
      expect(find.text('No hem trobat activitats'), findsOneWidget);
    },
  );

  testWidgets('Feed and search tolerate large text and narrow screens', (
    tester,
  ) async {
    await pumpScreen(tester, scale: 2);
    tester.view.physicalSize = const Size(320, 844);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Teatre sota les estrelles'),
      250,
    );
    expect(tester.takeException(), isNull);
    await pumpScreen(tester, search: true, scale: 2);
    tester.view.physicalSize = const Size(320, 844);
    await submit(tester, 'teatre');
    await tester.ensureVisible(find.text('M’hi apunto'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Leaving during a search ignores its late completion', (
    tester,
  ) async {
    final pending = Completer<List<Activity>>();
    repository.onSearch = (_) => pending.future;
    await pumpScreen(tester, search: true);
    await tester.enterText(find.byType(TextField), 'teatre');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    pending.complete(repository.results);
    await tester.pumpAndSettle();
    expect(opened, isNull);
    expect(tester.takeException(), isNull);
  });
}
