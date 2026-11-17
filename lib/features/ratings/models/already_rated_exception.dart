/// The user already rated this activity (R9: one rating per user and event).
class AlreadyRatedException implements Exception {
  const AlreadyRatedException();

  @override
  String toString() => 'AlreadyRatedException';
}
