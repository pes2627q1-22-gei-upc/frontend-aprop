/// Whether the signed-in person went to an activity they joined (#64, R8):
/// true = went, false = did not go, null = not answered yet.
abstract interface class AttendanceRepository {
  /// Throws on failure: an error must never look like «not answered».
  Future<bool?> getAttendance({
    required String userId,
    required String activityId,
  });

  /// Stores the answer; null clears it. Completes only once it is stored.
  Future<void> setAttendance({
    required String userId,
    required String activityId,
    required bool? attended,
  });
}

/// Why the server refused an answer.
enum AttendanceFailure implements Exception {
  /// The activity has not started yet (R8, 409).
  notStarted,

  /// The person is no longer signed up (404).
  notEnrolled,
}

/// Where the answers «No hi vaig anar» are kept on this device.
abstract interface class AttendanceMemory {
  Future<bool> saidNo({required String userId, required String activityId});

  Future<void> remember({
    required String userId,
    required String activityId,
    required bool saidNo,
  });
}
