import 'dart:async';

import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/presentation/view_models/activity_search_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_discovery_repository.dart';

void main() {
  late FakeDiscoveryRepository repository;
  late ActivitySearchViewModel viewModel;
  late List<Activity> activities;
  setUp(() async {
    repository = FakeDiscoveryRepository();
    activities = await DemoActivityRepository().getActivities();
    viewModel = ActivitySearchViewModel(repository: repository);
  });
  tearDown(() => viewModel.dispose());

  testWidgets('Typing is debounced and clearing cancels the scheduled search', (
    tester,
  ) async {
    viewModel.updateQuery('t');
    await tester.pump(const Duration(milliseconds: 200));
    viewModel.updateQuery('teatre');
    await tester.pump(const Duration(milliseconds: 349));
    expect(repository.queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(repository.queries, ['teatre']);
    expect(viewModel.hasSearched, isTrue);
    viewModel.updateQuery('jazz');
    viewModel.updateQuery('');
    await tester.pump(const Duration(seconds: 1));
    expect(repository.queries, ['teatre']);
    expect(viewModel.results, isEmpty);
    expect(viewModel.hasSearched, isFalse);
  });

  test(
    'Submission bypasses debounce, trims input and prevents duplicate requests',
    () async {
      final pending = Completer<List<Activity>>();
      repository.onSearch = (_) => pending.future;
      viewModel.updateQuery('  jazz  ');
      final search = viewModel.searchNow();
      await viewModel.searchNow();
      expect(repository.queries, ['jazz']);
      expect(viewModel.isSearching, isTrue);
      pending.complete(activities);
      await search;
      expect(viewModel.results, activities);
      expect(viewModel.hasSearched, isTrue);
      expect(() => viewModel.results.clear(), throwsUnsupportedError);
    },
  );

  test('Out of order responses cannot replace the latest search', () async {
    final old = Completer<List<Activity>>();
    final current = Completer<List<Activity>>();
    repository.onSearch = (query) =>
        query == 'old' ? old.future : current.future;
    viewModel.updateQuery('old');
    final oldRequest = viewModel.searchNow();
    viewModel.updateQuery('new');
    final newRequest = viewModel.searchNow();
    current.complete([activities.last]);
    await newRequest;
    old.complete([activities.first]);
    await oldRequest;
    expect(viewModel.query, 'new');
    expect(viewModel.results, [activities.last]);
    expect(viewModel.isSearching, isFalse);
  });

  test(
    'Editing immediately invalidates results even before the next request',
    () async {
      final pending = Completer<List<Activity>>();
      repository.onSearch = (_) => pending.future;
      viewModel.updateQuery('old');
      final request = viewModel.searchNow();
      viewModel.updateQuery('new');
      pending.complete(activities);
      await request;
      expect(viewModel.results, isEmpty);
      expect(viewModel.hasSearched, isFalse);
    },
  );

  test('A stale failure cannot stop the latest pending search', () async {
    final old = Completer<List<Activity>>();
    final current = Completer<List<Activity>>();
    repository.onSearch = (query) =>
        query == 'old' ? old.future : current.future;
    viewModel.updateQuery('old');
    final first = viewModel.searchNow();
    viewModel.updateQuery('new');
    final second = viewModel.searchNow();
    old.completeError(StateError('Offline'));
    await first;
    expect(viewModel.isSearching, isTrue);
    expect(viewModel.errorMessage, isNull);
    current.complete([]);
    await second;
    expect(viewModel.hasSearched, isTrue);
    expect(viewModel.results, isEmpty);
  });

  test('Clearing while loading rejects late results and does not search blank input', () async {
    final pending = Completer<List<Activity>>();
    repository.onSearch = (_) => pending.future;
    viewModel.updateQuery('jazz');
    final request = viewModel.searchNow();
    viewModel.updateQuery('   ');
    pending.complete(activities);
    await request;
    await viewModel.searchNow();
    expect(repository.queries, ['jazz']);
    expect(viewModel.results, isEmpty);
    expect(viewModel.hasSearched, isFalse);
  });

  test('Errors are distinct from zero results and can be retried', () async {
    repository.onSearch = (_) async => throw StateError('Offline');
    viewModel.updateQuery('teatre');
    await viewModel.searchNow();
    expect(viewModel.errorMessage, isNotNull);
    expect(viewModel.hasSearched, isFalse);
    repository.onSearch = null;
    await viewModel.searchNow();
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.hasSearched, isTrue);
    expect(viewModel.results, isEmpty);
  });

  test('Disposal cancels debounce and ignores late completions', () async {
    final pending = Completer<List<Activity>>();
    repository.onSearch = (_) => pending.future;
    final disposable = ActivitySearchViewModel(repository: repository);
    var notifications = 0;
    disposable.addListener(() => notifications++);
    disposable.updateQuery('jazz');
    final request = disposable.searchNow();
    disposable.dispose();
    final before = notifications;
    pending.complete(activities);
    await request;
    disposable.updateQuery('teatre');
    await disposable.searchNow();
    expect(notifications, before);
    expect(disposable.results, isEmpty);
    expect(repository.queries, ['jazz']);
  });
}
