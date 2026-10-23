import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/geo_bounds.dart';
import 'package:aprop/features/activities/repositories/activity_map_repository.dart';

class FakeActivityMapRepository implements ActivityMapRepository {
  final requestedAreas = <GeoBounds>[];

  /// Resposta de [getActivitiesInArea] si [loadArea] és nul.
  List<Activity> activities = const [];

  /// Si no és nul, decideix la resposta de cada zona (per fer-la fallar o
  /// esperar).
  Future<List<Activity>> Function(GeoBounds area)? loadArea;

  @override
  Future<List<Activity>> getActivitiesInArea(GeoBounds area) {
    requestedAreas.add(area);
    return loadArea?.call(area) ?? Future.value(activities);
  }

  @override
  Future<Activity?> getActivityById(String id) async =>
      activities.where((activity) => activity.id == id).firstOrNull;
}
