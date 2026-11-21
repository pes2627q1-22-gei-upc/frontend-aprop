import '../repositories/attendance_repository.dart';

/// Answers kept in memory during this run of the app.
class DemoAttendanceRepository implements AttendanceRepository {
  final _answers = <String, bool>{};

  String _key(String userId, String activityId) => '$userId/$activityId';

  @override
  Future<bool?> getAttendance({
    required String userId,
    required String activityId,
  }) async => _answers[_key(userId, activityId)];

  @override
  Future<void> setAttendance({
    required String userId,
    required String activityId,
    required bool? attended,
  }) async {
    final key = _key(userId, activityId);
    if (attended == null) {
      _answers.remove(key);
    } else {
      _answers[key] = attended;
    }
  }
}
