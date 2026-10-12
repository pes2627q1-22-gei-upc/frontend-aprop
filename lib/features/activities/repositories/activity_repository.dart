import '../models/activity.dart';

abstract interface class ActivityRepository {
  Future<List<Activity>> getActivities();
}
