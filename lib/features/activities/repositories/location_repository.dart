import '../models/geo_point.dart';

/// Troba on és un lloc per centrar-hi el mapa.
abstract interface class LocationRepository {
  /// Centre aproximat del municipi, o `null` si no es coneix.
  Future<GeoPoint?> findMunicipality(String name);
}
