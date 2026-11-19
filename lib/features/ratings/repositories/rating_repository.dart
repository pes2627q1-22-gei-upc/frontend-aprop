/// Rating of attended activities, from 1 to 5 stars (R9, R10).
abstract interface class RatingRepository {
  /// Completes only after the rating is stored; throws on failure.
  /// Throws `AlreadyRatedException` if [userId] already rated [activityId].
  /// Eligibility (attended, event over; R8/R10) is enforced by the server.
  Future<void> rate({
    required String userId,
    required String activityId,
    required int score,
  });

  /// Changes the user's own rating. Throws `RatingNotFoundException` if
  /// [userId] has not rated [activityId].
  Future<void> updateRating({
    required String userId,
    required String activityId,
    required int score,
  });

  /// Deletes the user's own rating. Throws `RatingNotFoundException` if
  /// [userId] has not rated [activityId].
  Future<void> deleteRating({
    required String userId,
    required String activityId,
  });
}
