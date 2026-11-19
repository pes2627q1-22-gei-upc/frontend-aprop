import '../../../core/network/api_client.dart';
import '../models/already_rated_exception.dart';
import '../models/rating_not_found_exception.dart';
import '../repositories/rating_repository.dart';

/// `POST /events/{id}/ratings` with `{score}`; the user comes from the token.
// TODO(DP-053): #184 (`feature/event-rating`, PR #59) returns 409 when already
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

  // TODO(DP-052): `PUT`/`DELETE /events/{id}/ratings/me` (#205) pending deploy.
  @override
  Future<void> updateRating({
    required String userId,
    required String activityId,
    required int score,
  }) async {
    if (score < 1 || score > 5) throw RangeError.range(score, 1, 5, 'score');
    try {
      await apiClient.putJson(
        'events/$activityId/ratings/me',
        body: {'score': score},
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) throw const RatingNotFoundException();
      rethrow;
    }
  }

  @override
  Future<void> deleteRating({
    required String userId,
    required String activityId,
  }) async {
    try {
      await apiClient.deleteJson('events/$activityId/ratings/me');
    } on ApiException catch (error) {
      if (error.statusCode == 404) throw const RatingNotFoundException();
      rethrow;
    }
  }
}
