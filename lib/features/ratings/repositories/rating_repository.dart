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
}
