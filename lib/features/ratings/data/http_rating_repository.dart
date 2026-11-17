import '../../../core/network/api_client.dart';
import '../repositories/rating_repository.dart';

/// `POST /events/{id}/ratings` with `{score}`; the user comes from the token.
// TODO(DP-048): backend #184 is not deployed and its error codes are unknown,
// so «already rated» is not mapped to `AlreadyRatedException` yet.
class HttpRatingRepository implements RatingRepository {
  HttpRatingRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<void> rate({
    required String userId,
    required String activityId,
    required int score,
  }) async {
    if (score < 1 || score > 5) throw RangeError.range(score, 1, 5, 'score');
    await apiClient.postJson(
      'events/$activityId/ratings',
      body: {'score': score},
    );
  }
}
