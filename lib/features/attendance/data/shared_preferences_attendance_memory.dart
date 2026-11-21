import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/attendance_repository.dart';

/// Keeps, per account, the activities answered «No hi vaig anar».
class SharedPreferencesAttendanceMemory implements AttendanceMemory {
  const SharedPreferencesAttendanceMemory();

  static String _key(String userId) => 'attendance.saidNo.$userId';

  @override
  Future<bool> saidNo({
    required String userId,
    required String activityId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key(userId))?.contains(activityId) ??
        false;
  }

  @override
  Future<void> remember({
    required String userId,
    required String activityId,
    required bool saidNo,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = {...?preferences.getStringList(_key(userId))};
    final changed = saidNo ? ids.add(activityId) : ids.remove(activityId);
    if (changed) await preferences.setStringList(_key(userId), ids.toList());
  }
}
