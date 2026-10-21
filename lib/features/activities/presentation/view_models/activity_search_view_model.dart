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
  String _query = '';
  String? _errorMessage;
  List<Activity> _results = const [];

  String get query => _query;
  bool get isSearching => _isSearching;
  bool get hasSearched => _hasSearched;
  String? get errorMessage => _errorMessage;
  List<Activity> get results => _results;

  void updateQuery(String value) {
    if (_isDisposed || value == _query) return;
    _debounce?.cancel();
    // Invalidate a pending response immediately, not after the debounce.
    _revision++;
    _query = value;
    _isSearching = false;
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
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.searchActivities(query);
      if (_isDisposed || revision != _revision) return;
      _results = List.unmodifiable(result);
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

  @override
  void dispose() {
    _isDisposed = true;
    _revision++;
    _debounce?.cancel();
    super.dispose();
  }
}
