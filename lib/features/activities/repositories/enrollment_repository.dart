/// Shared enrollment data. Implementations must keep users isolated.
abstract interface class EnrollmentRepository {
  /// Emits an immutable snapshot immediately on subscription and after changes.
  /// Errors indicate that the current enrollment state could not be read.
  Stream<Set<String>> watchEnrolledActivityIds(String userId);

  /// Completes only after enrollment is confirmed; throws on failure.
  /// Repeating an enrollment must not create a duplicate.
  Future<void> enroll({required String userId, required String activityId});

  /// Completes only after the enrollment is removed; throws on failure.
  /// Unenrolling from an activity without an enrollment changes nothing.
  Future<void> unenroll({required String userId, required String activityId});
}
