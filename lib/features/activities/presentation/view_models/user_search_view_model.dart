import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../../profile/models/user_summary.dart';
import '../../../profile/repositories/user_search_repository.dart';

/// People-search presentation state, independent of activity-search state.
class UserSearchViewModel extends ChangeNotifier {
  UserSearchViewModel({
    required this.repository,
    this.debounceDuration = const Duration(milliseconds: 350),
  });

  final UserSearchRepository repository;
  final Duration debounceDuration;
  Timer? _debounce;
  bool _isDisposed = false;
  int _revision = 0;
  String _query = '';
  List<UserSummary> _results = const [];
  int _totalCount = 0;
  int? _nextPage;
  bool _hasSearched = false;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _pageError;

  String get query => _query;
  List<UserSummary> get results => _results;
  int get totalCount => _totalCount;
  bool get hasMore => _nextPage != null;
  bool get hasSearched => _hasSearched;
  bool get isSearching => _isSearching;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get pageError => _pageError;

  void updateQuery(String query) {
    if (_isDisposed || query == _query) return;
    _debounce?.cancel();
    _revision++;
    _query = query;
    _results = const [];
    _totalCount = 0;
    _nextPage = null;
    _hasSearched = false;
    _isSearching = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _pageError = null;
    if (query.trim().runes.length > userSearchQueryLimit) {
      _errorMessage = currentL10n.userSearchTooLong(userSearchQueryLimit);
    } else if (query.trim().isNotEmpty) {
      _debounce = Timer(debounceDuration, searchNow);
    }
    notifyListeners();
  }

  Future<void> searchNow() async {
    if (_isDisposed || _isSearching) return;
    _debounce?.cancel();
    final query = _query.trim();
    if (query.isEmpty || query.runes.length > userSearchQueryLimit) return;
    final revision = ++_revision;
    _isSearching = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _pageError = null;
    notifyListeners();
    try {
      final result = await repository.searchUsers(query);
      if (_isDisposed || revision != _revision) return;
      final unique = {for (final user in result.users) user.id: user};
      _results = List.unmodifiable(unique.values);
      _totalCount = result.totalCount;
      _nextPage = result.nextPage;
      _hasSearched = true;
    } catch (_) {
      if (!_isDisposed && revision == _revision) {
        _errorMessage = currentL10n.userSearchError;
      }
    } finally {
      if (!_isDisposed && revision == _revision) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    final page = _nextPage;
    if (_isDisposed || _isSearching || _isLoadingMore || page == null) return;
    final revision = _revision;
    _isLoadingMore = true;
    _pageError = null;
    notifyListeners();
    try {
      final result = await repository.searchUsers(_query.trim(), page: page);
      if (_isDisposed || revision != _revision) return;
      if (result.nextPage != null && result.nextPage! <= page) {
        throw StateError('User search cursor did not advance');
      }
      final unique = {for (final user in _results) user.id: user};
      for (final user in result.users) {
        unique.putIfAbsent(user.id, () => user);
      }
      _results = List.unmodifiable(unique.values);
      _totalCount = result.totalCount;
      _nextPage = result.nextPage;
    } catch (_) {
      if (!_isDisposed && revision == _revision) {
        _pageError = currentL10n.userSearchMoreError;
      }
    } finally {
      if (!_isDisposed && revision == _revision) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _revision++;
    _debounce?.cancel();
    super.dispose();
  }
}
