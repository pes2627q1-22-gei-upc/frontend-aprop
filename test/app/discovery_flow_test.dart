import 'dart:async';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/data/demo_discovery_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/discovery_feed.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/activities/fake_activity_repository.dart';
import '../features/activities/fake_discovery_repository.dart';
import '../features/activities/fake_enrollment_repository.dart';

void main() {
  late DemoAuthRepository auth;
  late FakeActivityRepository catalogue;
  late FakeDiscoveryRepository discovery;
  late FakeEnrollmentRepository enrollments;
  late Activity exhibition;
  const user = 'demo-laiasoler';

  setUp(() async {
    auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    exhibition = Activity(
      id: 'demo-exhibition',
      title: 'Mirades de Catalunya',
      category: 'Exposicions',
      municipality: 'Girona',
      startsAt: DateTime.now(),
      imageAsset: 'assets/images/mirades_de_catalunya.jpg',
      source: ActivitySource.culturalAgenda,
    );
    catalogue = FakeActivityRepository()..activities = [exhibition];
    catalogue.findActivity = (id) async {
      for (final activity in catalogue.activities) {
        if (activity.id == id) return activity;
      }
      return null;
    };
    discovery = FakeDiscoveryRepository()
      ..feed = DiscoveryFeed(recommended: [exhibition], featured: [])
      ..onPage = (query, page) =>
          DemoDiscoveryRepository(activityRepository: catalogue)
              .searchActivitiesPage(query, page: page);
    enrollments = FakeEnrollmentRepository();
  });
  tearDown(() => enrollments.dispose());

  Finder destination(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      APropApp(
        authRepository: auth,
        activityRepository: catalogue,
        enrollmentRepository: enrollments,
        discoveryRepository: discovery,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(destination('Inici'));
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.tap(find.byKey(const ValueKey('discover-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), query);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  testWidgets('Search enrollment is shared by detail, Inici and Agenda', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(const ValueKey('discover-search')), findsOneWidget);
    // Des de la #273 l'assistent també és a Inici.
    expect(find.text('Assistent'), findsOneWidget);
    await search(tester, 'girona');
    expect(find.text('1 activitat trobada'), findsOneWidget);
    await tester.ensureVisible(find.text('M’hi apunto'));
    await tester.tap(find.text('M’hi apunto'));
    await tester.pumpAndSettle();
    expect(enrollments.enrolledRequests, ['$user/demo-exhibition']);
    expect(find.widgetWithText(AppBar, 'Cerca'), findsOneWidget);
    await tester.ensureVisible(find.text('Mirades de Catalunya'));
    await tester.tap(find.text('Mirades de Catalunya'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
    expect(find.text('Apuntat'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0, // Inici (Descobreix)
    );
    await tester.tap(find.byTooltip('Tornar enrere'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'girona',
    );
    await tester.tap(destination('Mapa'));
    await tester.pumpAndSettle();
    expect(find.text('Apuntat'), findsOneWidget);
    await tester.tap(destination('Agenda'));
    await tester.pumpAndSettle();
    expect(find.text('Mirades de Catalunya'), findsOneWidget);
    expect(enrollments.enrolledRequests, hasLength(1));
  });

  testWidgets(
    'Returning from details or switching tabs preserves the query and results',
    (tester) async {
      await pumpApp(tester);
      await search(tester, 'girona');
      await tester.tap(find.text('Mirades de Catalunya'));
      await tester.pumpAndSettle();
      expect(enrollments.enrolledRequests, isEmpty);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      await tester.tap(destination('Mapa'));
      await tester.pumpAndSettle();
      await tester.tap(destination('Inici'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Cerca'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'girona',
      );
      expect(find.text('1 activitat trobada'), findsOneWidget);
      expect(discovery.queries, ['girona']);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('discover-search')), findsOneWidget);
      expect(find.text('Per a tu'), findsOneWidget);
    },
  );

  testWidgets('Feed scroll survives a detail route and section changes', (
    tester,
  ) async {
    catalogue.activities = [
      for (var i = 0; i < 25; i++)
        Activity(
          id: 'event-$i',
          title: 'Activitat $i',
          category: exhibition.category,
          municipality: exhibition.municipality,
          startsAt: exhibition.startsAt,
          imageAsset: exhibition.imageAsset,
          source: exhibition.source,
        ),
    ];
    discovery.feed = DiscoveryFeed(
      recommended: catalogue.activities,
      featured: [],
    );
    await pumpApp(tester);
    final card = find.byKey(const ValueKey('discover-recommended-event-12'));
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('discover-feed')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(card).dy;
    await tester.tap(
      find.descendant(of: card, matching: find.text('Activitat 12')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tornar enrere'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(card).dy, closeTo(before, 1));
    await tester.tap(destination('Mapa'));
    await tester.pumpAndSettle();
    await tester.tap(destination('Inici'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(card).dy, closeTo(before, 1));
  });

  testWidgets('Search scroll survives a detail route and section changes', (
    tester,
  ) async {
    catalogue.activities = [
      for (var i = 0; i < 25; i++)
        Activity(
          id: 'event-$i',
          title: 'Activitat $i',
          category: exhibition.category,
          municipality: exhibition.municipality,
          startsAt: exhibition.startsAt,
          imageAsset: exhibition.imageAsset,
          source: exhibition.source,
        ),
    ];
    await pumpApp(tester);
    await search(tester, 'activitat');
    final card = find.byKey(const ValueKey('activity-search-event-12'));
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find.descendant(
        of: find.byKey(
          const PageStorageKey('activity-search-results-activitat'),
        ),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(card).dy;
    await tester.tap(
      find.descendant(of: card, matching: find.text('Activitat 12')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tornar enrere'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(card).dy, closeTo(before, 1));
    await tester.tap(destination('Mapa'));
    await tester.pumpAndSettle();
    await tester.tap(destination('Inici'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(card).dy, closeTo(before, 1));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'activitat',
    );
    expect(discovery.queries, ['activitat']);
  });

  testWidgets('An old account search cannot populate the next account screen', (
    tester,
  ) async {
    final pending = Completer<List<Activity>>();
    discovery.onSearch = (_) => pending.future;
    discovery.onFeed = (id) async => id == user
        ? discovery.feed
        : DiscoveryFeed(recommended: [], featured: []);
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('discover-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'girona');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await auth.signOut();
    await tester.pumpAndSettle();
    await auth.register(
      firstName: 'Pol',
      lastName: 'Vidal',
      username: 'pol',
      email: 'pol@example.test',
      password: 'Password1!',
    );
    await auth.checkEmailVerified();
    await tester.pumpAndSettle();
    await tester.tap(destination('Inici'));
    await tester.pumpAndSettle();
    pending.complete([exhibition]);
    await tester.pumpAndSettle();
    expect(find.text('Encara no hi ha propostes'), findsOneWidget);
    expect(find.text('1 activitat trobada'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Default composition makes the mockup selections searchable', (
    tester,
  ) async {
    final demo = DemoActivityRepository();
    await tester.pumpWidget(
      APropApp(
        authRepository: auth,
        activityRepository: demo,
        enrollmentRepository: enrollments,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(destination('Inici'));
    await tester.pumpAndSettle();
    expect(find.text('Mirades de Catalunya'), findsOneWidget);
    await search(tester, 'teatre');
    expect(find.text('Teatre sota les estrelles'), findsOneWidget);
    expect(find.text('1 activitat trobada'), findsOneWidget);
    expect(find.text('Publicat per Laia Soler'), findsOneWidget);
  });
}
