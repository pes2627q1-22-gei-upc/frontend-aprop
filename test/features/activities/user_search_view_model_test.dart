import 'dart:async';

import 'package:aprop/features/activities/presentation/view_models/user_search_view_model.dart';
import 'package:aprop/features/profile/models/user_search_page.dart';
import 'package:aprop/features/profile/models/user_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../profile/fake_user_search_repository.dart';

const _laia = UserSummary(
  id: 'laia',
  username: 'laiasoler',
  displayName: 'Laia Soler',
);
const _marc = UserSummary(
  id: 'marc',
  username: 'marcvidal',
  displayName: 'Marc Vidal',
);

void main() {
  late FakeUserSearchRepository repository;
  late UserSearchViewModel viewModel;
  setUp(() {
    repository = FakeUserSearchRepository()..users = [_laia];
    viewModel = UserSearchViewModel(repository: repository);
  });
  tearDown(() => viewModel.dispose());

  testWidgets('Typing is debounced; clearing cancels the scheduled request', (
    tester,
  ) async {
    viewModel.updateQuery('l');
    await tester.pump(const Duration(milliseconds: 200));
    viewModel.updateQuery('laia');
    await tester.pump(const Duration(milliseconds: 349));
    expect(repository.requests, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(repository.requests, [(query: 'laia', page: 0)]);
    expect(viewModel.results, [_laia]);
    viewModel.updateQuery('marc');
    viewModel.updateQuery('');
    await tester.pump(const Duration(seconds: 1));
    expect(repository.requests, hasLength(1));
    expect(viewModel.results, isEmpty);
    expect(viewModel.hasSearched, isFalse);
  });

  test('Submission trims input and prevents duplicate requests', () async {
    final pending = Completer<UserSearchPage>();
    repository.onSearch = (_, _) => pending.future;
    viewModel.updateQuery(' laia ');
    final request = viewModel.searchNow();
    await viewModel.searchNow();
    expect(repository.requests, [(query: 'laia', page: 0)]);
    pending.complete(UserSearchPage(users: [_laia], totalCount: 1));
    await request;
    expect(viewModel.hasSearched, isTrue);
    expect(() => viewModel.results.clear(), throwsUnsupportedError);
  });

  test('Old results and failures cannot replace a newer query', () async {
    final old = Completer<UserSearchPage>();
    final current = Completer<UserSearchPage>();
    repository.onSearch = (query, _) =>
        query == 'old' ? old.future : current.future;
    viewModel.updateQuery('old');
    final first = viewModel.searchNow();
    viewModel.updateQuery('new');
    final second = viewModel.searchNow();
    old.completeError(StateError('Offline'));
    await first;
    expect(viewModel.isSearching, isTrue);
    expect(viewModel.errorMessage, isNull);
    current.complete(UserSearchPage(users: [_marc], totalCount: 1));
    await second;
    expect(viewModel.results, [_marc]);
  });

  test('Clearing a pending query rejects its late response', () async {
    final pending = Completer<UserSearchPage>();
    repository.onSearch = (_, _) => pending.future;
    viewModel.updateQuery('laia');
    final request = viewModel.searchNow();
    viewModel.updateQuery('   ');
    pending.complete(UserSearchPage(users: [_laia], totalCount: 1));
    await request;
    await viewModel.searchNow();
    expect(viewModel.results, isEmpty);
    expect(viewModel.hasSearched, isFalse);
    expect(repository.requests, hasLength(1));
  });

  test('Errors are distinct from empty results and allow retry', () async {
    repository.onSearch = (_, _) async => throw StateError('Offline');
    viewModel.updateQuery('laia');
    await viewModel.searchNow();
    expect(viewModel.errorMessage, isNotNull);
    expect(viewModel.hasSearched, isFalse);
    repository.onSearch = null;
    repository.users = [];
    await viewModel.searchNow();
    expect(viewModel.errorMessage, isNull);
    expect(viewModel.hasSearched, isTrue);
    expect(viewModel.totalCount, 0);
  });

  test(
    'Pagination keeps results on error, retries and deduplicates IDs',
    () async {
      var fail = true;
      repository.onSearch = (_, page) async {
        if (page == 0) {
          return UserSearchPage(users: [_laia], totalCount: 2, nextPage: 1);
        }
        if (fail) throw StateError('Offline');
        return UserSearchPage(users: [_laia, _marc], totalCount: 2);
      };
      viewModel.updateQuery('a');
      await viewModel.searchNow();
      await viewModel.loadMore();
      expect(viewModel.results, [_laia]);
      expect(viewModel.pageError, isNotNull);
      fail = false;
      await viewModel.loadMore();
      expect(viewModel.results, [_laia, _marc]);
      expect(viewModel.pageError, isNull);
      expect(viewModel.hasMore, isFalse);
    },
  );

  test(
    'Refreshing invalidates a pending continuation and serializes pages',
    () async {
      final pending = Completer<UserSearchPage>();
      repository.onSearch = (_, page) async => page == 0
          ? UserSearchPage(users: [_laia], totalCount: 2, nextPage: 1)
          : pending.future;
      viewModel.updateQuery('a');
      await viewModel.searchNow();
      final more = viewModel.loadMore();
      await viewModel.loadMore();
      expect(repository.requests.where((r) => r.page == 1), hasLength(1));
      await viewModel.searchNow();
      pending.complete(UserSearchPage(users: [_marc], totalCount: 2));
      await more;
      expect(viewModel.results, [_laia]);
      expect(viewModel.isLoadingMore, isFalse);
    },
  );

  test('Overlong Unicode queries never reach the repository', () async {
    viewModel.updateQuery(List.filled(101, '😀').join());
    await viewModel.searchNow();
    expect(repository.requests, isEmpty);
    expect(viewModel.errorMessage, isNotNull);
    viewModel.updateQuery(List.filled(100, '😀').join());
    await viewModel.searchNow();
    expect(repository.requests, hasLength(1));
  });

  testWidgets('Disposal cancels the debounce and ignores pending replies', (
    tester,
  ) async {
    viewModel.updateQuery('laia');
    viewModel.dispose();
    await tester.pump(const Duration(seconds: 1));
    expect(repository.requests, isEmpty);
    viewModel = UserSearchViewModel(repository: repository);
    final pending = Completer<UserSearchPage>();
    repository.onSearch = (_, _) => pending.future;
    viewModel.updateQuery('marc');
    final request = viewModel.searchNow();
    viewModel.dispose();
    pending.complete(UserSearchPage(users: [_marc], totalCount: 1));
    await request;
    expect(viewModel.results, isEmpty);
    // Replace the disposed instance for the common tearDown.
    viewModel = UserSearchViewModel(repository: repository);
  });
}
