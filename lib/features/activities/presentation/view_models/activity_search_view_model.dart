import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/activity.dart';
import '../../repositories/discovery_repository.dart';

class ActivitySearchViewModel extends ChangeNotifier {
  ActivitySearchViewModel({
    required this.repository,
    this.debounceDuration = const Duration(milliseconds: 350),
  });

  final DiscoveryRepository repository;
  final Duration debounceDuration;
  Timer? _debounce;
  int _revision = 0;
  bool _isDisposed = false;
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isLoadingMore = false;
  int? _nextPage;
  int _totalCount = 0;
  String? _pageError;
  String _query = '';
  String? _errorMessage;
  List<Activity> _results = const [];

  String get query => _query;
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;
  String? get errorMessage => _errorMessage;
  List<Activity> get results => _results;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextPage != null;
  int get totalCount => _totalCount;
  String? get pageError => _pageError;

  void updateQuery(String value) {
    if (_isDisposed || value == _query) return;
    _debounce?.cancel();
    // Invalidate a pending response immediately, not after the debounce.
    _revision++;
    _query = value;
    _isSearching = false;
    _isLoadingMore = false;
    _nextPage = null;
    _totalCount = 0;
    _pageError = null;
    _hasSearched = false;
    _errorMessage = null;
    _results = const [];
    if (value.trim().isNotEmpty) {
      _debounce = Timer(debounceDuration, searchNow);
    }
    notifyListeners();
  }

  Future<void> searchNow() async {
    if (_isDisposed || _isSearching) return;
    _debounce?.cancel();
    final query = _query.trim();
    if (query.isEmpty) return;
    final revision = ++_revision;
    _isSearching = true;
    _isLoadingMore = false;
    _pageError = null;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.searchActivitiesPage(query);
      if (_isDisposed || revision != _revision) return;
      _results = List.unmodifiable(result.activities);
      _totalCount = result.totalCount;
      _nextPage = result.nextPage;
      _hasSearched = true;
    } catch (_) {
      if (_isDisposed || revision != _revision) return;
      _errorMessage = 'No hem pogut cercar les activitats. Torna-ho a provar.';
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
    final query = _query.trim();
    _isLoadingMore = true;
    _pageError = null;
    notifyListeners();
    try {
      final result = await repository.searchActivitiesPage(query, page: page);
      if (_isDisposed || revision != _revision) return;
      if (result.nextPage != null && result.nextPage! <= page) {
        throw StateError('Search cursor did not advance');
      }
      final unique = {for (final activity in _results) activity.id: activity};
      for (final activity in result.activities) {
        unique.putIfAbsent(activity.id, () => activity);
      }
      _results = List.unmodifiable(unique.values);
      _totalCount = result.totalCount;
      _nextPage = result.nextPage;
    } catch (_) {
      if (!_isDisposed && revision == _revision) {
        _pageError = 'No hem pogut carregar més activitats. Torna-ho a provar.';
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
