import 'dart:async';

import 'package:aprop/features/activities/models/activity_filters.dart';
import 'package:aprop/features/activities/models/activity_page.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'activity_filter_test_data.dart';
import 'fake_paged_activity_repository.dart';

void main() {
  late FakePagedActivityRepository repository;
  late ActivitiesViewModel model;
  final music = event('music', DateTime(2026, 11, 14));
  final theatre = event('theatre', DateTime(2026, 11, 14), category: 'Teatre');
  final next = event('next', DateTime(2026, 11, 15), category: 'Teatre');
  final selected = ActivityFilters(categories: ['Teatre']);

  setUp(() {
    repository = FakePagedActivityRepository();
    model = ActivitiesViewModel(repository: repository, pageSize: 1);
  });
  tearDown(() => model.dispose());

  test(
    'A filtered query replaces pages and ignores an older initial response',
    () async {
      final old = Completer<ActivityPage>();
      repository.onPage = (_) => old.future;
      final initial = model.load();
      repository.onPage = (_) async =>
          ActivityPage(items: [theatre], hasMore: true);
      await model.applyFilters(selected);
      old.complete(ActivityPage(items: [music], hasMore: true));
      await initial;
      expect(model.activities.map((activity) => activity.id), ['theatre']);
      expect(repository.pagesRequested, [0, 0]);
      expect(repository.requestedFilters, [ActivityFilters(), selected]);
      repository.onPage = (_) async =>
          ActivityPage(items: [next], hasMore: false);
      await model.loadMore();
      expect(repository.pagesRequested, [0, 0, 1]);
      expect(repository.requestedFilters.last, selected);
      expect(model.activities.map((activity) => activity.id), [
        'theatre',
        'next',
      ]);
    },
  );

  test(
    'An old append cannot restore cards or errors after filters change',
    () async {
      repository.onPage = (_) async =>
          ActivityPage(items: [music], hasMore: true);
      await model.load();
      final old = Completer<ActivityPage>();
      repository.onPage = (_) => old.future;
      final append = model.loadMore();
      repository.onPage = (_) async =>
          ActivityPage(items: [theatre], hasMore: false);
      await model.applyFilters(selected);
      old.completeError(StateError('old query failed'));
      await append;
      expect(model.activities.single.id, 'theatre');
      expect(model.loadMoreError, isNull);
      expect(model.isLoadingMore, isFalse);
      expect(model.hasMore, isFalse);
    },
  );

  test(
    'Failed filter changes never display the previous query as matching',
    () async {
      repository.onPage = (_) async =>
          ActivityPage(items: [music], hasMore: true);
      await model.load();
      repository.onPage = (_) async => throw StateError('offline');
      await model.applyFilters(selected);
      expect(model.filters, selected);
      expect(model.activities, isEmpty);
      expect(model.hasLoaded, isFalse);
      expect(model.errorMessage, isNotNull);
      repository.onPage = (_) async =>
          ActivityPage(items: [theatre], hasMore: false);
      await model.load();
      expect(repository.pagesRequested, [0, 0, 0]);
      expect(model.errorMessage, isNull);
      expect(model.activities.single.id, 'theatre');
      await model.applyFilters(ActivityFilters(categories: ['Teatre']));
      expect(repository.pagesRequested, [0, 0, 0]);
    },
  );

  test('Clearing filters starts from page zero with no restrictions', () async {
    repository.activities = [music, theatre];
    await model.applyFilters(selected);
    expect(model.activities.single.id, 'theatre');
    await model.clearFilters();
    expect(repository.pagesRequested, [0, 0]);
    expect(repository.requestedFilters.last!.isActive, isFalse);
    expect(model.activities.single.id, 'music');
    await model.loadMore();
    expect(model.activities.map((activity) => activity.id), [
      'music',
      'theatre',
    ]);
  });

  test(
    'Category metadata loading is deduplicated and retries an error',
    () async {
      final pending = Completer<List<String>>();
      var calls = 0;
      repository.onCategories = () {
        calls++;
        return pending.future;
      };
      final loading = model.loadFilterCategories();
      await model.loadFilterCategories();
      expect(model.isLoadingCategories, isTrue);
      pending.completeError(StateError('offline'));
      await loading;
      expect(model.categoriesError, isNotNull);
      expect(calls, 1);
      repository.onCategories = () async {
        calls++;
        return ['Concerts', 'Teatre'];
      };
      await model.loadFilterCategories();
      await model.loadFilterCategories();
      expect(model.categoriesError, isNull);
      expect(model.filterCategories, ['Concerts', 'Teatre']);
      expect(calls, 2);
      expect(() => model.filterCategories.clear(), throwsUnsupportedError);
      expect(model.filters.isActive, isFalse);
    },
  );

  test('Disposing an account ignores late metadata', () async {
    final pending = Completer<List<String>>();
    repository.onCategories = () => pending.future;
    final loading = model.loadFilterCategories();
    final disposed = model;
    disposed.dispose();
    model = ActivitiesViewModel(repository: repository);
    pending.complete(['Teatre']);
    await loading;
    expect(disposed.filterCategories, isEmpty);
    expect(model.filterCategories, isEmpty);
  });
}
