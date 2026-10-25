import 'dart:async';

import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/activity_filters.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'activity_filter_test_data.dart';
import 'fake_activity_repository.dart';

class _Repository extends FakeActivityRepository {
  Future<List<Activity>> Function()? onLoad;

  @override
  Future<List<Activity>> getActivities() async {
    listRequests++;
    return onLoad == null ? activities : await onLoad!();
  }
}

void main() {
  late _Repository repository;
  late ActivitiesViewModel model;
  setUp(() {
    repository = _Repository()
      ..activities = [
        event('music', DateTime(2026, 9, 26)),
        event('theatre', DateTime(2026, 9, 27), category: 'Teatre'),
      ];
    model = ActivitiesViewModel(repository: repository);
  });
  tearDown(() => model.dispose());

  test(
    'Applying and clearing filters preserves source data without new requests',
    () async {
      await model.load();
      var notifications = 0;
      model.addListener(() => notifications++);
      final selected = ActivityFilters(categories: ['Teatre']);
      model.applyFilters(selected);
      expect(model.activities.map((a) => a.id), ['theatre']);
      model.applyFilters(ActivityFilters(categories: ['Teatre']));
      expect(notifications, 1);
      expect(repository.listRequests, 1);
      model.clearFilters();
      expect(model.activities, repository.activities);
      expect(() => model.activities.clear(), throwsUnsupportedError);
    },
  );

  test(
    'An in-flight load uses the latest confirmed filters and is deduplicated',
    () async {
      final pending = Completer<List<Activity>>();
      repository.onLoad = () => pending.future;
      final loading = model.load();
      await model.load();
      model.applyFilters(ActivityFilters(categories: ['Teatre']));
      pending.complete(repository.activities);
      await loading;
      expect(repository.listRequests, 1);
      expect(model.activities.map((a) => a.id), ['theatre']);
      expect(model.isLoading, isFalse);
    },
  );

  test('Refresh errors retain filters and data; retry includes newly created matches', () async {
    await model.load();
    model.applyFilters(ActivityFilters(categories: ['Música']));
    repository.onLoad = () async => throw StateError('offline');
    await model.load();
    expect(model.errorMessage, isNotNull);
    expect(model.filters.categories, {'Música'});
    expect(model.activities.map((a) => a.id), ['music']);
    repository.onLoad = null;
    repository.activities = [
      ...repository.activities,
      event('new', DateTime(2026, 10)),
    ];
    await model.load();
    expect(model.errorMessage, isNull);
    expect(model.activities.map((a) => a.id), ['music', 'new']);
  });

  test('A disposed account ignores late responses and filter writes', () async {
    final pending = Completer<List<Activity>>();
    repository.onLoad = () => pending.future;
    final loading = model.load();
    model.dispose();
    pending.complete(repository.activities);
    await loading;
    model.applyFilters(ActivityFilters(categories: ['Teatre']));
    expect(model.activities, isEmpty);
    expect(model.filters.isActive, isFalse);
    model = ActivitiesViewModel(repository: repository);
  });
}
