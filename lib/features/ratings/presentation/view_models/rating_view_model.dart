import 'package:flutter/foundation.dart';

import '../../models/already_rated_exception.dart';
import '../../models/rating_not_found_exception.dart';
import '../../repositories/rating_repository.dart';

/// Ratings of the signed-in user, shared by the details and the agenda.
class RatingViewModel extends ChangeNotifier {
  RatingViewModel({required this.userId, required this._repository});

  final String userId;
  final RatingRepository _repository;
  final Map<String, int> _scores = {};
  final Set<String> _alreadyRated = {};
  final Set<String> _submitting = {};
  final Map<String, String> _errors = {};
  bool _isDisposed = false;

  /// Score sent in this session; null if unrated or rated earlier.
  int? scoreFor(String activityId) => _scores[activityId];
  bool hasRated(String activityId) =>
      _scores.containsKey(activityId) || _alreadyRated.contains(activityId);
  bool isSubmitting(String activityId) => _submitting.contains(activityId);
  String? errorFor(String activityId) => _errors[activityId];

  Future<void> submit(String activityId, int score) async {
    if (_isDisposed ||
        score < 1 ||
        score > 5 ||
        hasRated(activityId) ||
        isSubmitting(activityId)) {
      return;
    }
    _submitting.add(activityId);
    _errors.remove(activityId);
    notifyListeners();
    try {
      await _repository.rate(
        userId: userId,
        activityId: activityId,
        score: score,
      );
      _scores[activityId] = score;
    } on AlreadyRatedException {
      _alreadyRated.add(activityId);
    } catch (_) {
      _errors[activityId] =
          'No hem pogut desar la valoració. Torna-ho a provar.';
    } finally {
      _submitting.remove(activityId);
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Changes an existing rating. Returns whether it succeeded.
  Future<bool> update(String activityId, int score) async {
    if (score < 1 || score > 5 || !hasRated(activityId)) return false;
    return _mutate(
      activityId,
      () => _repository.updateRating(
        userId: userId,
        activityId: activityId,
        score: score,
      ),
      onSuccess: () => _scores[activityId] = score,
      failure: 'No hem pogut modificar la valoració. Torna-ho a provar.',
    );
  }

  /// Deletes an existing rating, which can then be given again.
  Future<bool> remove(String activityId) async {
    if (!hasRated(activityId)) return false;
    return _mutate(
      activityId,
      () => _repository.deleteRating(userId: userId, activityId: activityId),
      onSuccess: () => _forget(activityId),
      failure: 'No hem pogut eliminar la valoració. Torna-ho a provar.',
      goneIsSuccess: true,
    );
  }

  /// Drops a stale error, e.g. when the user enters or leaves edit mode.
  void clearError(String activityId) {
    if (_errors.remove(activityId) != null && !_isDisposed) notifyListeners();
  }

  void _forget(String activityId) {
    _scores.remove(activityId);
    _alreadyRated.remove(activityId);
  }

  Future<bool> _mutate(
    String activityId,
    Future<void> Function() call, {
    required void Function() onSuccess,
    required String failure,
    bool goneIsSuccess = false,
  }) async {
    if (_isDisposed || isSubmitting(activityId)) return false;
    _submitting.add(activityId);
    _errors.remove(activityId);
    notifyListeners();
    try {
      await call();
      onSuccess();
      return true;
    } on RatingNotFoundException {
      // Gone on the server: stop showing it as rated.
      // Deleting something already gone is the outcome the user wanted.
      _forget(activityId);
      if (goneIsSuccess) return true;
      _errors[activityId] = 'La valoració ja no existeix.';
      return false;
    } catch (_) {
      _errors[activityId] = failure;
      return false;
    } finally {
      _submitting.remove(activityId);
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
