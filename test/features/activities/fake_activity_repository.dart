import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/repositories/activity_repository.dart';

class FakeActivityRepository implements ActivityRepository {
  Future<Activity?> Function(String id)? findActivity;
  final requestedIds = <String>[];
  int listRequests = 0;

  @override
  Future<List<Activity>> getActivities() async {
    listRequests++;
    return const [];
  }

  @override
  Future<Activity?> getActivityById(String id) {
    requestedIds.add(id);
    return findActivity?.call(id) ?? Future.value(null);
  }
}
