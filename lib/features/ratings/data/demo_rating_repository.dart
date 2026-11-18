import '../models/already_rated_exception.dart';
import '../models/rating_not_found_exception.dart';
import '../repositories/rating_repository.dart';

/// In-memory ratings, kept until app shutdown.
// TODO(DP-048): replace with `HttpRatingRepository` once #184 is deployed.
class DemoRatingRepository implements RatingRepository {
  final Map<String, Map<String, int>> _scoresByUser = {};

  @override
  Future<void> rate({
    required String userId,
    required String activityId,
    required int score,
  }) async {
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');
    if (score < 1 || score > 5) throw RangeError.range(score, 1, 5, 'score');
    final scores = _scoresByUser.putIfAbsent(userId, () => {});
    if (scores.containsKey(activityId)) throw const AlreadyRatedException();
    scores[activityId] = score;
  }

  @override
  Future<void> updateRating({
    required String userId,
    required String activityId,
    required int score,
  }) async {
    if (score < 1 || score > 5) throw RangeError.range(score, 1, 5, 'score');
    final scores = _scoresByUser[userId];
    if (scores == null || !scores.containsKey(activityId)) {
      throw const RatingNotFoundException();
    }
    scores[activityId] = score;
  }

  @override
  Future<void> deleteRating({
    required String userId,
    required String activityId,
  }) async {
    if (_scoresByUser[userId]?.remove(activityId) == null) {
      throw const RatingNotFoundException();
    }
  }
}
