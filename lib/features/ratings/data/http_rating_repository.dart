import '../../../core/network/api_client.dart';
import '../models/already_rated_exception.dart';
import '../repositories/rating_repository.dart';

/// `POST /events/{id}/ratings` with `{score}`; the user comes from the token.
// TODO(DP-048): #184 (`feature/event-rating`, PR #59) returns 409 when already
// rated, 403 when not attended and 404 when missing; pending deploy to Render.
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
    try {
      await apiClient.postJson(
        'events/$activityId/ratings',
        body: {'score': score},
      );
    } on ApiException catch (error) {
      if (error.statusCode == 409) throw const AlreadyRatedException();
      rethrow;
    }
  }
}
