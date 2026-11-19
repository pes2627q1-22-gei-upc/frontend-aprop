import '../models/activity.dart';
import '../models/activity_filters.dart';
import '../models/activity_page.dart';
import '../models/new_activity.dart';
import 'activity_details_repository.dart';

abstract interface class ActivityRepository
    implements ActivityDetailsRepository {
  Future<List<Activity>> getActivities();

  /// Loads one zero-based page, preserving the source's order. Throws on a
  /// request or decoding failure; an empty result is a valid catalogue end.
  Future<ActivityPage> getActivitiesPage({
    int page = 0,
    int pageSize = 50,
    ActivityFilters? filters,
  });

  /// Available category labels from the same source as the catalogue.
  /// Throws on a loading/decoding failure; an empty list is valid.
  Future<List<String>> getFilterCategories();

  /// Returns null when the activity does not exist.
  @override
  Future<Activity?> getActivityById(String id);

  /// Publica una activitat no oficial i la retorna amb el seu ID. Llança una
  /// excepció si no s'ha pogut crear.
  Future<Activity> createActivity(NewActivity activity);

  /// Desa els canvis d'una activitat no oficial de qui l'ha creada i la
  /// retorna actualitzada. Llança una excepció si no s'ha pogut desar (per
  /// exemple, si qui ho demana no n'és qui l'ha creada).
  Future<Activity> updateActivity(String id, NewActivity activity);
}
