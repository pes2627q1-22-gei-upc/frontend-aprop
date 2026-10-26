import 'dart:async';

import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/activity_filters.dart';
import 'package:aprop/features/activities/models/activity_page.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'activity_filter_test_data.dart';
import 'fake_paged_activity_repository.dart';

void main() {
  late FakePagedActivityRepository repository;
  late ActivitiesViewModel model;
  final a = event('a', DateTime(2026, 11, 20));
  final b = event('b', DateTime(2026, 11, 1));
  final c = event('c', DateTime(2026, 11, 25), category: 'Teatre');

  ActivityPage page(List<Activity> items, {bool more = false}) =>
      ActivityPage(items: items, hasMore: more);

  setUp(() {
    repository = FakePagedActivityRepository()
      ..onPage = (index) async =>
          index == 0 ? page([a, b], more: true) : page([b, c]);
    model = ActivitiesViewModel(repository: repository, pageSize: 2);
  });
  tearDown(() => model.dispose());

  test(
    'Starts at zero, preserves source order and appends unique IDs',
    () async {
      await model.load();
      expect(repository.pagesRequested, [0]);
      expect(model.activities.map((a) => a.id), ['a', 'b']);
      expect(model.hasMore, isTrue);
      await model.loadMore();
      expect(repository.pagesRequested, [0, 1]);
      expect(model.activities.map((a) => a.id), ['a', 'b', 'c']);
      expect(model.loadedCount, 3);
      expect(model.hasMore, isFalse);
      expect(() => model.activities.clear(), throwsUnsupportedError);
      await model.loadMore();
      expect(repository.pagesRequested, [0, 1]);
    },
  );

  test(
    'Concurrent next-page requests are deduplicated and use current filters',
    () async {
      await model.load();
      final pending = Completer<ActivityPage>();
      repository.onPage = (_) => pending.future;
      final loading = model.loadMore();
      await model.loadMore();
      expect(model.isLoadingMore, isTrue);
      expect(model.isLoading, isFalse);
      final filtered = model.applyFilters(
        ActivityFilters(categories: ['Teatre']),
      );
      pending.complete(page([c]));
      await loading;
      await filtered;
      expect(repository.pagesRequested, [0, 1, 0]);
      expect(model.activities.map((a) => a.id), ['c']);
      expect(model.isLoadingMore, isFalse);
    },
  );

  test(
    'An append error keeps existing cards and retries the same page',
    () async {
      await model.load();
      repository.onPage = (_) async => throw StateError('offline');
      await model.loadMore();
      expect(model.errorMessage, isNull);
      expect(model.loadMoreError, isNotNull);
      expect(model.activities.map((a) => a.id), ['a', 'b']);
      expect(model.hasMore, isTrue);
      repository.onPage = (_) async => page([c]);
      await model.loadMore();
      expect(repository.pagesRequested, [0, 1, 1]);
      expect(model.loadMoreError, isNull);
      expect(model.loadedCount, 3);
    },
  );

  test(
    'A refresh invalidates an older append even if it finishes afterwards',
    () async {
      await model.load();
      final pending = Completer<ActivityPage>();
      repository.onPage = (index) =>
          index == 1 ? pending.future : Future.value(page([c]));
      final append = model.loadMore();
      await model.load();
      pending.complete(page([a, b], more: true));
      await append;
      expect(model.activities.map((a) => a.id), ['c']);
      expect(model.hasMore, isFalse);
      expect(model.isLoadingMore, isFalse);
    },
  );

  test(
    'Failed refresh retains catalogue and continuation; retry resets to zero',
    () async {
      await model.load();
      await model.applyFilters(ActivityFilters(categories: ['Música']));
      repository.onPage = (_) async => throw StateError('offline');
      await model.load();
      expect(model.errorMessage, isNotNull);
      expect(model.hasLoaded, isTrue);
      expect(model.hasMore, isTrue);
      expect(model.loadedCount, 2);
      expect(model.filters.categories, {'Música'});
      repository.onPage = (_) async => page([b]);
      await model.load();
      expect(repository.pagesRequested, [0, 0, 0, 0]);
      expect(model.errorMessage, isNull);
      expect(model.activities.map((a) => a.id), ['b']);
      expect(model.hasMore, isFalse);
    },
  );

  test('Overlapping category batches advance without duplicate cards or false errors', () async {
    await model.load();
    repository.onPage = (_) async => page([a, b], more: true);
    await model.loadMore();
    expect(model.loadMoreError, isNull);
    expect(model.loadedCount, 2);
    repository.onPage = (_) async => page([c]);
    await model.loadMore();
    expect(repository.pagesRequested, [0, 1, 2]);
    expect(model.loadMoreError, isNull);
  });

  test('Initial failure is distinct from a valid empty catalogue', () async {
    repository.onPage = (_) async => throw StateError('offline');
    await model.load();
    expect(model.hasLoaded, isFalse);
    expect(model.errorMessage, isNotNull);
    repository.onPage = (_) async => page([]);
    await model.load();
    expect(model.hasLoaded, isTrue);
    expect(model.activities, isEmpty);
    expect(model.errorMessage, isNull);
    expect(model.hasMore, isFalse);
  });

  test(
    'Disposal ignores a late page without notifying a destroyed account',
    () async {
      await model.load();
      final pending = Completer<ActivityPage>();
      repository.onPage = (_) => pending.future;
      final loading = model.loadMore();
      final previous = model;
      previous.dispose();
      model = ActivitiesViewModel(repository: repository);
      pending.complete(page([c]));
      await loading;
      expect(previous.loadedCount, 2);
      expect(model.loadedCount, 0);
    },
  );
}
