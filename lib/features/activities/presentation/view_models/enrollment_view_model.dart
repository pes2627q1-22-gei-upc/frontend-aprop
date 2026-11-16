import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../repositories/enrollment_repository.dart';

/// How long a plan removed from a list can still be recovered with «Desfer».
const unenrollUndoDelay = Duration(seconds: 5);

/// One presentation state per signed-in user, shared by list and details.
class EnrollmentViewModel extends ChangeNotifier {
  EnrollmentViewModel({required this.userId, required this._repository});

  final String userId;
  final EnrollmentRepository _repository;
  StreamSubscription<Set<String>>? _subscription;
  Set<String> _enrolledActivityIds = const {};
  final Set<String> _pendingActivityIds = {};
  final Set<String> _unenrollingActivityIds = {};
  final Map<String, String> _errors = {};
  final Map<String, String> _unenrollErrors = {};

  /// Plans removed with [unenrollLater]: they already look removed, but the
  /// backend is only told when the timer ends. The timer is no longer active
  /// while that request is being sent.
  final Map<String, Timer> _deferredUnenrolls = {};
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isDisposed = false;
  int _subscriptionVersion = 0;
  String? _loadError;

  Set<String> get enrolledActivityIds => _deferredUnenrolls.isEmpty
      ? _enrolledActivityIds
      : Set.unmodifiable(
          _enrolledActivityIds.where((id) => !isUnenrollDeferred(id)),
        );
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get loadError => _loadError;
  bool isEnrolled(String id) =>
      _enrolledActivityIds.contains(id) && !isUnenrollDeferred(id);

  /// True from [unenrollLater] until the backend has answered.
  bool isUnenrollDeferred(String id) => _deferredUnenrolls.containsKey(id);
  bool isEnrolling(String id) => _pendingActivityIds.contains(id);
  bool isUnenrolling(String id) => _unenrollingActivityIds.contains(id);
  String? errorFor(String id) => _errors[id] ?? _unenrollErrors[id];

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
              // Each error stops applying once the plan reaches the state the
              // failed action wanted.
              _errors.removeWhere((id, _) => ids.contains(id));
              _unenrollErrors.removeWhere((id, _) => !ids.contains(id));
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
    // Joining again while «Desfer» is still possible is the same as undoing:
    // the backend never heard about the removal.
    if (isUnenrollDeferred(activityId)) {
      undoUnenroll(activityId);
      return;
    }
    if (_isDisposed ||
        !_hasLoaded ||
        _isLoading ||
        _loadError != null ||
        isEnrolled(activityId) ||
        isEnrolling(activityId) ||
        isUnenrolling(activityId)) {
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

  /// Removes a confirmed plan. The screen asks the user first, so an
  /// accidental tap does not remove it.
  Future<void> unenroll(String activityId) async {
    if (!_canUnenroll(activityId)) return;

    _unenrollingActivityIds.add(activityId);
    _unenrollErrors.remove(activityId);
    notifyListeners();
    try {
      await _sendUnenroll(activityId);
    } finally {
      if (!_isDisposed) {
        _unenrollingActivityIds.remove(activityId);
        notifyListeners();
      }
    }
  }

  /// Removes a plan from the lists at once, without asking, and tells the
  /// backend after [delay] unless [undoUnenroll] is called first.
  void unenrollLater(String activityId, {Duration delay = unenrollUndoDelay}) {
    if (!_canUnenroll(activityId)) return;

    _unenrollErrors.remove(activityId);
    _deferredUnenrolls[activityId] = Timer(delay, () async {
      try {
        await _sendUnenroll(activityId);
      } finally {
        if (!_isDisposed) {
          _deferredUnenrolls.remove(activityId);
          notifyListeners();
        }
      }
    });
    notifyListeners();
  }

  /// Keeps a plan removed with [unenrollLater]. Too late once the request has
  /// been sent.
  void undoUnenroll(String activityId) {
    final timer = _deferredUnenrolls[activityId];
    if (_isDisposed || timer == null || !timer.isActive) return;
    timer.cancel();
    _deferredUnenrolls.remove(activityId);
    notifyListeners();
  }

  bool _canUnenroll(String activityId) =>
      !_isDisposed &&
      _hasLoaded &&
      !_isLoading &&
      _loadError == null &&
      isEnrolled(activityId) &&
      !isEnrolling(activityId) &&
      !isUnenrolling(activityId);

  Future<void> _sendUnenroll(String activityId) async {
    try {
      await _repository.unenroll(userId: userId, activityId: activityId);
      if (_isDisposed) return;
      _enrolledActivityIds = Set.unmodifiable(
        _enrolledActivityIds.where((id) => id != activityId),
      );
    } catch (_) {
      if (_isDisposed) return;
      _unenrollErrors[activityId] =
          'No t’hem pogut desapuntar. Torna-ho a provar.';
    }
  }

  @override
  void dispose() {
    // Removals still waiting for «Desfer» go ahead: the user already saw the
    // plan disappear (for example, before signing out).
    for (final MapEntry(key: activityId, value: timer)
        in _deferredUnenrolls.entries) {
      if (!timer.isActive) continue;
      timer.cancel();
      unawaited(
        _repository
            .unenroll(userId: userId, activityId: activityId)
            .catchError((Object _) {}),
      );
    }
    _isDisposed = true;
    _subscriptionVersion++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
