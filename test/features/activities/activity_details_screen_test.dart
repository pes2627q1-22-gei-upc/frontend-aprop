import 'dart:async';

import 'package:aprop/app/navigation/activity_details_route.dart';
import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/presentation/formatters/activity_date_formatter.dart';
import 'package:aprop/features/activities/presentation/screens/activity_details_screen.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:aprop/features/activities/repositories/activity_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_activity_repository.dart';
import 'fake_enrollment_repository.dart';

void main() {
  Future<void> pumpDetails(
    WidgetTester tester, {
    String id = 'demo-jazz',
    ActivityRepository? repository,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final enrollments = FakeEnrollmentRepository();
    final enrollmentViewModel = EnrollmentViewModel(
      userId: 'test-user',
      repository: enrollments,
    );
    enrollmentViewModel.load();
    addTearDown(() async {
      enrollmentViewModel.dispose();
      await enrollments.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: ActivityDetailsScreen(
          activityId: id,
          repository: repository ?? DemoActivityRepository(),
          enrollmentViewModel: enrollmentViewModel,
        ),
      ),
    );
  }

  test('Demo details reuse catalogue IDs and handle unknown IDs', () async {
    final repository = DemoActivityRepository();
    for (final activity in await repository.getActivities()) {
      expect(await repository.getActivityById(activity.id), same(activity));
    }
    expect(await repository.getActivityById('missing'), isNull);
  });

  test('Date formatting includes the actual day and year on details', () {
    final date = DateTime(2026, 9, 26, 9, 5);
    expect(formatActivitySchedule(date), 'Dissabte · 09.05 h');
    expect(
      formatActivitySchedule(date, includeDate: true),
      'Dissabte 26 de setembre de 2026 · 09.05 h',
    );
  });

  testWidgets('Shows loading until the detail request completes', (
    tester,
  ) async {
    final result = Completer<Activity?>();
    final repository = FakeActivityRepository()
      ..findActivity = (_) => result.future;
    await pumpDetails(tester, repository: repository);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    result.complete(
      await DemoActivityRepository().getActivityById('demo-jazz'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jazz al parc'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Shows official data and enables enrollment', (tester) async {
    await pumpDetails(tester);
    await tester.pumpAndSettle();

    expect(find.text('Jazz al parc'), findsOneWidget);
    expect(find.text('Barcelona'), findsOneWidget);
    expect(find.textContaining('26 de setembre de 2026'), findsOneWidget);
    expect(find.text('Publicat per'), findsNothing);
    final enroll = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'M’hi apunto'),
    );
    expect(enroll.onPressed, isNotNull);
    await tester.scrollUntilVisible(
      find.text('Font: Agenda Cultural · Generalitat'),
      200,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shows the community creator and friendship badge', (
    tester,
  ) async {
    await pumpDetails(tester, id: 'demo-theatre');
    await tester.pumpAndSettle();
    expect(find.text('Teatre sota les estrelles'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Laia Soler'), 150);
    expect(find.text('Publicat per'), findsOneWidget);
    expect(find.text('Amiga'), findsOneWidget);
    expect(find.text('Font: Agenda Cultural · Generalitat'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unknown ID shows an honest not-found state', (tester) async {
    await pumpDetails(tester, id: 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No hem trobat aquesta activitat.'), findsOneWidget);
    expect(find.text('M’hi apunto'), findsNothing);
  });

  testWidgets('Retry reloads the same activity after a failure', (
    tester,
  ) async {
    final repository = FakeActivityRepository()
      ..findActivity = (_) async => throw Exception('Offline');
    await pumpDetails(tester, repository: repository);
    await tester.pumpAndSettle();
    expect(find.textContaining('No hem pogut carregar'), findsOneWidget);

    repository.findActivity = (_) =>
        DemoActivityRepository().getActivityById('demo-jazz');
    await tester.tap(find.text('Tornar-ho a provar'));
    await tester.pumpAndSettle();
    expect(find.text('Jazz al parc'), findsOneWidget);
    expect(repository.requestedIds, ['demo-jazz', 'demo-jazz']);
  });

  testWidgets('Large text remains scrollable and the action stays visible', (
    tester,
  ) async {
    await pumpDetails(tester, id: 'demo-theatre', textScale: 2);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sobre l’activitat'), 200);
    expect(find.text('M’hi apunto').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Missing descriptions and images have fallbacks', (tester) async {
    final repository = FakeActivityRepository()
      ..findActivity = (_) async => Activity(
        id: 'no-description',
        title: 'Activitat de prova',
        category: 'Música',
        municipality: 'Barcelona',
        startsAt: DateTime(2026, 9, 26, 19),
        imageAsset: 'assets/images/missing.jpg',
        source: ActivitySource.culturalAgenda,
      );
    await pumpDetails(tester, id: 'no-description', repository: repository);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Encara no hi ha una descripció disponible.'),
      200,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('The shared route opens by ID without an activities list', (
    tester,
  ) async {
    final repository = FakeActivityRepository()
      ..findActivity = (_) =>
          DemoActivityRepository().getActivityById('demo-theatre');
    final enrollments = FakeEnrollmentRepository();
    final enrollmentViewModel = EnrollmentViewModel(
      userId: 'test-user',
      repository: enrollments,
    );
    enrollmentViewModel.load();
    addTearDown(() async {
      enrollmentViewModel.dispose();
      await enrollments.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                activityDetailsRoute(
                  activityId: 'demo-theatre',
                  repository: repository,
                  enrollmentViewModel: enrollmentViewModel,
                ),
              ),
              child: const Text('Obrir des de l’agenda'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Obrir des de l’agenda'));
    await tester.pumpAndSettle();
    expect(find.text('Teatre sota les estrelles'), findsOneWidget);
    expect(repository.listRequests, 0);
    await tester.tap(find.byTooltip('Tornar enrere'));
    await tester.pumpAndSettle();
    expect(find.text('Obrir des de l’agenda').hitTestable(), findsOneWidget);
  });
}
