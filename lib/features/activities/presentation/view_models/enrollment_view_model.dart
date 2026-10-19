import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../repositories/enrollment_repository.dart';

/// One presentation state per signed-in user, shared by list and details.
class EnrollmentViewModel extends ChangeNotifier {
  EnrollmentViewModel({required this.userId, required this._repository});

  final String userId;
  final EnrollmentRepository _repository;
  StreamSubscription<Set<String>>? _subscription;
  Set<String> _enrolledActivityIds = const {};
  final Set<String> _pendingActivityIds = {};
  final Map<String, String> _errors = {};
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isDisposed = false;
  int _subscriptionVersion = 0;
  String? _loadError;

  Set<String> get enrolledActivityIds => _enrolledActivityIds;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get loadError => _loadError;
  bool isEnrolled(String id) => _enrolledActivityIds.contains(id);
  bool isEnrolling(String id) => _pendingActivityIds.contains(id);
  String? errorFor(String id) => _errors[id];

  Future<void> load() async {
    if (_isDisposed || _isLoading) return;
    final version = ++_subscriptionVersion;
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      await _subscription?.cancel();
      if (_isDisposed || version != _subscriptionVersion) return;
      _subscription = _repository
          .watchEnrolledActivityIds(userId)
          .listen(
            (ids) {
              if (_isDisposed || version != _subscriptionVersion) return;
              _enrolledActivityIds = Set.unmodifiable(ids);
              _hasLoaded = true;
              _isLoading = false;
              _loadError = null;
              _errors.removeWhere((id, _) => ids.contains(id));
              notifyListeners();
            },
            onError: (Object error, StackTrace stackTrace) =>
                _onReadError(version),
            onDone: () => _onReadError(version),
          );
    } catch (_) {
      _onReadError(version);
    }
  }

  void _onReadError(int version) {
    if (_isDisposed || version != _subscriptionVersion) return;
    _isLoading = false;
    _loadError = 'No hem pogut consultar els teus plans. Torna-ho a provar.';
    notifyListeners();
  }

  Future<void> enroll(String activityId) async {
    if (_isDisposed ||
        !_hasLoaded ||
        _isLoading ||
        _loadError != null ||
        isEnrolled(activityId) ||
        isEnrolling(activityId)) {
      return;
    }

    _pendingActivityIds.add(activityId);
    _errors.remove(activityId);
    notifyListeners();
    try {
      await _repository.enroll(userId: userId, activityId: activityId);
      if (_isDisposed) return;
      _enrolledActivityIds = Set.unmodifiable({
        ..._enrolledActivityIds,
        activityId,
      });
      _errors.remove(activityId);
    } catch (_) {
      if (_isDisposed) return;
      _errors[activityId] = 'No t’hi hem pogut apuntar. Torna-ho a provar.';
    } finally {
      if (!_isDisposed) {
        _pendingActivityIds.remove(activityId);
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscriptionVersion++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
