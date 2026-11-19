/// The user has no rating for this activity (nothing to edit or delete).
class RatingNotFoundException implements Exception {
  const RatingNotFoundException();

  @override
  String toString() => 'RatingNotFoundException';
}
