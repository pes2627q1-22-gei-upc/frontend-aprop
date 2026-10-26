import '../models/activity.dart';
import '../models/activity_page.dart';
import '../models/new_activity.dart';
import 'activity_details_repository.dart';

abstract interface class ActivityRepository
    implements ActivityDetailsRepository {
  Future<List<Activity>> getActivities();

  /// Loads one zero-based page, preserving the source's order. Throws on a
  /// request or decoding failure; an empty result is a valid catalogue end.
  Future<ActivityPage> getActivitiesPage({int page = 0, int pageSize = 50});

  /// Returns null when the activity does not exist.
  @override
  Future<Activity?> getActivityById(String id);

  /// Publica una activitat no oficial i la retorna amb el seu ID. Llança una
  /// excepció si no s'ha pogut crear.
  Future<Activity> createActivity(NewActivity activity);
}
