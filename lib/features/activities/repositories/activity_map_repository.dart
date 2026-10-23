import '../models/activity.dart';
import '../models/geo_bounds.dart';
import 'activity_details_repository.dart';

/// Activitats del mapa d'Inici, carregades per zona visible. La fitxa que s'obre
/// des del mapa es llegeix de la mateixa font.
abstract interface class ActivityMapRepository
    implements ActivityDetailsRepository {
  /// Activitats amb ubicació dins d'[area]. Llança una excepció si no s'han
  /// pogut carregar.
  Future<List<Activity>> getActivitiesInArea(GeoBounds area);
}
