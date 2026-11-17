import 'package:flutter/foundation.dart';

import '../../models/already_rated_exception.dart';
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

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
