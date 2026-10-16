import '../models/activity.dart';

abstract interface class ActivityRepository {
  Future<List<Activity>> getActivities();

  /// Returns null when the activity does not exist.
  Future<Activity?> getActivityById(String id);
}
