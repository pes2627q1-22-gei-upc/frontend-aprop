import '../models/activity.dart';
import '../models/new_activity.dart';

abstract interface class ActivityRepository {
  Future<List<Activity>> getActivities();

  /// Returns null when the activity does not exist.
  Future<Activity?> getActivityById(String id);

  /// Publica una activitat no oficial i la retorna amb el seu ID. Llança una
  /// excepció si no s'ha pogut crear.
  Future<Activity> createActivity(NewActivity activity);
}
