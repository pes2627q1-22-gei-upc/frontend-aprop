import 'dart:async';

import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/discovery_feed.dart';
import 'package:aprop/features/activities/presentation/view_models/discover_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_discovery_repository.dart';

void main() {
  late FakeDiscoveryRepository repository;
  late DiscoverViewModel viewModel;
  setUp(() {
    repository = FakeDiscoveryRepository();
    viewModel = DiscoverViewModel(repository: repository, userId: 'adam');
  });
  tearDown(() => viewModel.dispose());

  test('Loads the correct account and blocks overlapping requests', () async {
    final pending = Completer<DiscoveryFeed>();
    repository.onFeed = (_) => pending.future;
    final load = viewModel.load();
    await viewModel.load();
    expect(repository.users, ['adam']);
    expect(viewModel.isLoading, isTrue);
    expect(viewModel.feed, isNull);
    pending.complete(repository.feed);
    await load;
    expect(viewModel.feed!.isEmpty, isTrue);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
  });

  test(
    'A failed refresh retains the previous feed and can be retried',
    () async {
      repository.feed = DiscoveryFeed(
        recommended: await DemoActivityRepository().getActivities(),
        featured: [],
      );
      await viewModel.load();
      final previous = viewModel.feed;
      repository.onFeed = (_) async => throw StateError('Offline');
      await viewModel.load();
      expect(viewModel.feed, same(previous));
      expect(viewModel.errorMessage, isNotNull);
      repository.onFeed = null;
      await viewModel.load();
      expect(viewModel.errorMessage, isNull);
    },
  );

  test(
    'Initial failure has no feed rather than a successful empty state',
    () async {
      repository.onFeed = (_) async => throw StateError('Offline');
      await viewModel.load();
      expect(viewModel.feed, isNull);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.isLoading, isFalse);
    },
  );

  test('Disposed models ignore late responses and later calls', () async {
    final pending = Completer<DiscoveryFeed>();
    repository.onFeed = (_) => pending.future;
    final disposable = DiscoverViewModel(repository: repository, userId: 'old');
    var notifications = 0;
    disposable.addListener(() => notifications++);
    final load = disposable.load();
    disposable.dispose();
    pending.complete(repository.feed);
    await load;
    await disposable.load();
    expect(notifications, 1);
    expect(disposable.feed, isNull);
    expect(repository.users, ['old']);
  });
}
