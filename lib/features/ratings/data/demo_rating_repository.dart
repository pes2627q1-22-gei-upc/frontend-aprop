import '../models/already_rated_exception.dart';
import '../repositories/rating_repository.dart';

/// In-memory ratings, kept until app shutdown.
// TODO(DP-053): replace with `HttpRatingRepository` once #184 is deployed.
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

  /// Every score recorded for [activityId], from any user.
  Iterable<int> scoresFor(String activityId) => [
    for (final scores in _scoresByUser.values) ?scores[activityId],
  ];
}
