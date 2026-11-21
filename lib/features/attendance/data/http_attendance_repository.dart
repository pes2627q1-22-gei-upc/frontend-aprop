import '../../../core/network/api_client.dart';
import '../repositories/attendance_repository.dart';

/// `GET` and `PATCH /events/{id}/enrollment/attendance`; the person comes
/// from the session token.
// TODO(DP-068): `GET` only says `has-attended`, so «did not go» and «not
// answered» both read as null here. `RememberedAttendanceRepository` keeps the
// «No» answers on the device until the API returns the stored value.
class HttpAttendanceRepository implements AttendanceRepository {
  HttpAttendanceRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<bool?> getAttendance({
    required String userId,
    required String activityId,
  }) async {
    final decoded = await apiClient.getJson(
      'events/${Uri.encodeComponent(activityId)}/enrollment/attendance',
    );
    if (decoded is! Map<String, Object?> || decoded['has-attended'] is! bool) {
      throw const FormatException('Expected has-attended');
    }
    return decoded['has-attended'] == true ? true : null;
  }

  @override
  Future<void> setAttendance({
    required String userId,
    required String activityId,
    required bool? attended,
  }) async {
    try {
      await apiClient.patchJson(
        'events/${Uri.encodeComponent(activityId)}/enrollment/attendance',
        body: {'attendance': attended},
      );
    } on ApiException catch (error) {
      throw switch (error.statusCode) {
        409 => AttendanceFailure.notStarted,
        404 => AttendanceFailure.notEnrolled,
        _ => error,
      };
    }
  }
}
