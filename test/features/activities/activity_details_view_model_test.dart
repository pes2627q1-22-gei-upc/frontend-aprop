import 'dart:async';

import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/presentation/view_models/activity_details_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_activity_repository.dart';

void main() {
  late FakeActivityRepository repository;
  late ActivityDetailsViewModel viewModel;
  late Activity jazz;

  setUp(() async {
    repository = FakeActivityRepository();
    jazz = (await DemoActivityRepository().getActivityById('demo-jazz'))!;
    viewModel = ActivityDetailsViewModel(
      activityId: jazz.id,
      repository: repository,
    );
  });

  tearDown(() => viewModel.dispose());

  test('Loads by ID without loading the catalogue first', () async {
    final result = Completer<Activity?>();
    repository.findActivity = (_) => result.future;

    final loading = viewModel.load();
    expect(viewModel.isLoading, isTrue);
    expect(viewModel.activity, isNull);

    result.complete(jazz);
    await loading;

    expect(repository.requestedIds, ['demo-jazz']);
    expect(repository.listRequests, 0);
    expect(viewModel.activity, same(jazz));
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
  });

  test('Missing activity is different from a repository failure', () async {
    await viewModel.load();
    expect(viewModel.activity, isNull);
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.isLoading, isFalse);
  });

  test('A failed request can be retried successfully', () async {
    repository.findActivity = (_) async => throw Exception('Offline');
    await viewModel.load();
    expect(viewModel.errorMessage, isNotNull);
    expect(viewModel.isLoading, isFalse);

    repository.findActivity = (_) async => jazz;
    await viewModel.load();
    expect(viewModel.activity, same(jazz));
    expect(viewModel.errorMessage, isNull);
  });

  test('Repeated loads do not issue overlapping requests', () async {
    final result = Completer<Activity?>();
    repository.findActivity = (_) => result.future;
    final loading = viewModel.load();
    await viewModel.load();
    expect(repository.requestedIds, hasLength(1));
    result.complete(jazz);
    await loading;
  });

  test('A response after disposal does not update or notify', () async {
    final result = Completer<Activity?>();
    final disposable = ActivityDetailsViewModel(
      activityId: jazz.id,
      repository: repository,
    );
    repository.findActivity = (_) => result.future;
    var notifications = 0;
    disposable.addListener(() => notifications++);

    final loading = disposable.load();
    disposable.dispose();
    result.complete(jazz);
    await loading;

    expect(notifications, 1);
    expect(disposable.activity, isNull);
    await disposable.load();
    expect(repository.requestedIds, hasLength(1));
  });
}
