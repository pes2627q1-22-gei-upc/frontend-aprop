import '../models/activity.dart';
import '../models/new_activity.dart';
import 'activity_details_repository.dart';

abstract interface class ActivityRepository
    implements ActivityDetailsRepository {
  Future<List<Activity>> getActivities();

  /// Returns null when the activity does not exist.
  @override
  Future<Activity?> getActivityById(String id);

  /// Publica una activitat no oficial i la retorna amb el seu ID. Llança una
  /// excepció si no s'ha pogut crear.
  Future<Activity> createActivity(NewActivity activity);
}
