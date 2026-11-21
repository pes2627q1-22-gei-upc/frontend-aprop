import '../models/activity.dart';
import '../models/activity_filters.dart';
import '../models/activity_page.dart';
import '../models/new_activity.dart';
import '../repositories/activity_details_repository.dart';
import '../repositories/activity_repository.dart';

/// Uneix el catàleg (encara de demostració) amb les activitats del backend que
/// arriben pel mapa.
///
/// Sense això, una activitat oberta des del mapa no es trobaria en apuntar-s'hi
/// ni a l'Agenda, perquè només es buscaria al catàleg. Els ID del backend són
/// números i els de demostració comencen per `demo-`, així que no es poden
/// confondre.
// TODO(DP-029): quan la llista també vingui del backend, sobrarà.
class CombinedActivityRepository implements ActivityRepository {
  CombinedActivityRepository({required this.catalogue, required this.backend});

  final ActivityRepository catalogue;
  final ActivityDetailsRepository backend;

  @override
  Future<List<Activity>> getActivities() => catalogue.getActivities();

  @override
  Future<ActivityPage> getActivitiesPage({
    int page = 0,
    int pageSize = 50,
    ActivityFilters? filters,
  }) => catalogue.getActivitiesPage(
    page: page,
    pageSize: pageSize,
    filters: filters,
  );

  @override
  Future<List<String>> getFilterCategories() => catalogue.getFilterCategories();

  @override
  Future<Activity?> getActivityById(String id) {
    return int.tryParse(id) == null
        ? catalogue.getActivityById(id)
        : backend.getActivityById(id);
  }

  @override
  Future<Activity> createActivity(NewActivity activity) {
    return catalogue.createActivity(activity);
  }

  @override
  Future<Activity> updateActivity(String id, NewActivity activity) {
    return catalogue.updateActivity(id, activity);
  }

  @override
  Future<void> cancelActivity(String id) => catalogue.cancelActivity(id);
}
