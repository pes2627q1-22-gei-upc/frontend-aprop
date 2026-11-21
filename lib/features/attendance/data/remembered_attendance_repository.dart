import '../repositories/attendance_repository.dart';

/// Adds the «No hi vaig anar» answers kept on the device to a source that
/// cannot return them (DP-067).
class RememberedAttendanceRepository implements AttendanceRepository {
  RememberedAttendanceRepository({required this.inner, required this.memory});

  final AttendanceRepository inner;
  final AttendanceMemory memory;

  @override
  Future<bool?> getAttendance({
    required String userId,
    required String activityId,
  }) async {
    final attended = await inner.getAttendance(
      userId: userId,
      activityId: activityId,
    );
    if (attended != null) return attended;
    // A device that cannot read its memory asks again: never invent a «No».
    try {
      if (await memory.saidNo(userId: userId, activityId: activityId)) {
        return false;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> setAttendance({
    required String userId,
    required String activityId,
    required bool? attended,
  }) async {
    await inner.setAttendance(
      userId: userId,
      activityId: activityId,
      attended: attended,
    );
    try {
      await memory.remember(
        userId: userId,
        activityId: activityId,
        saidNo: attended == false,
      );
    } catch (_) {
      // The server already has the answer; only this device may ask again.
    }
  }
}
