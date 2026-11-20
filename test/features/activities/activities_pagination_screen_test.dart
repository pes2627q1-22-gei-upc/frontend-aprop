import 'dart:async';

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/models/activity_filters.dart';
import 'package:aprop/features/activities/models/activity_page.dart';
import 'package:aprop/features/activities/presentation/screens/activities_screen.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_view_model.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'activity_filter_test_data.dart';
import 'fake_enrollment_repository.dart';
import 'fake_paged_activity_repository.dart';

void main() {
  late FakePagedActivityRepository repository;
  late ActivitiesViewModel model;
  late EnrollmentViewModel enrollment;
  late List<String> opened;
  final first = event('First activity', DateTime(2026, 11, 14));
  final second = event(
    'Second activity',
    DateTime(2026, 11, 15),
    category: 'Teatre',
  );
  final more = find.byKey(const ValueKey('activities-load-more'));
  final list = find.byKey(const PageStorageKey<String>('activities-list'));

  setUp(() {
    repository = FakePagedActivityRepository()
      ..onPage = (index) async => ActivityPage(
        items: [index == 0 ? first : second],
        hasMore: index == 0,
      );
    model = ActivitiesViewModel(repository: repository, pageSize: 1);
    enrollment = EnrollmentViewModel(
      userId: 'user',
      repository: FakeEnrollmentRepository(),
    )..load();
    opened = [];
  });
  tearDown(() {
    model.dispose();
    enrollment.dispose();
  });

  Future<void> pump(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = scale > 1
        ? const Size(320, 700)
        : const Size(390, 844);
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
            enrollmentViewModel: enrollment,
            onActivitySelected: opened.add,
            // La llista només surt si Google Maps no es pot dibuixar (#274).
            googleMapsAvailable: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reach(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.descendant(of: list, matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Appending shows progress, retains position and opens the new activity',
    (tester) async {
      await pump(tester);
      await reach(tester, more);
      final offset = tester.widget<ListView>(list).controller!.offset;
      final pending = Completer<ActivityPage>();
      repository.onPage = (_) => pending.future;
      await tester.tap(more);
      await tester.pump();
      expect(model.loadedCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(ActivityPage(items: [second], hasMore: false));
      await tester.pumpAndSettle();
      expect(tester.widget<ListView>(list).controller!.offset, offset);
      expect(model.loadedCount, 2);
      expect(more, findsNothing);
      await reach(tester, find.text(second.title));
      await tester.tap(find.text(second.title));
      expect(opened, [second.id]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Append failure offers retry without replacing existing activities',
    (tester) async {
      await pump(tester);
      repository.onPage = (_) async => throw StateError('offline');
      await reach(tester, more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(find.text(model.loadMoreError!), findsOneWidget);
      expect(model.loadedCount, 1);
      repository.onPage = (_) async =>
          ActivityPage(items: [second], hasMore: false);
      await reach(tester, more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(repository.pagesRequested, [0, 1, 1]);
      expect(model.loadedCount, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'A locally filtered page does not claim the whole catalogue is empty',
    (tester) async {
      await model.applyFilters(ActivityFilters(categories: ['Teatre']));
      await pump(tester);
      expect(
        find.text('Cap coincidència entre les activitats carregades'),
        findsOneWidget,
      );
      await reach(tester, more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(find.text(second.title), findsOneWidget);
      expect(
        find.text('Cap coincidència entre les activitats carregades'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Refresh errors and next-page controls remain usable with doubled text',
    (tester) async {
      await pump(tester, scale: 2);
      repository.onPage = (_) async => throw StateError('offline');
      await model.load();
      await tester.pumpAndSettle();
      await reach(tester, more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(model.loadedCount, 1);
      expect(tester.takeException(), isNull);
      await reach(tester, more);
      expect(more.hitTestable(), findsOneWidget);
    },
  );
}
