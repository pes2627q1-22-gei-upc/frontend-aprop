import '../models/geo_point.dart';
import '../repositories/location_repository.dart';

/// Centres aproximats d'alguns municipis de Catalunya, mentre no hi ha cap
/// servei per passar d'un nom a coordenades.
// TODO(DP-020): substituir per geocodificació (backend o API de Google).
class DemoLocationRepository implements LocationRepository {
  const DemoLocationRepository();

  static const _municipalities = {
    'barcelona': GeoPoint(latitude: 41.3874, longitude: 2.1686),
    'badalona': GeoPoint(latitude: 41.4500, longitude: 2.2474),
    "l'hospitalet de llobregat": GeoPoint(latitude: 41.3597, longitude: 2.0997),
    'sabadell': GeoPoint(latitude: 41.5463, longitude: 2.1086),
    'terrassa': GeoPoint(latitude: 41.5610, longitude: 2.0089),
    'sant cugat del valles': GeoPoint(latitude: 41.4720, longitude: 2.0860),
    'granollers': GeoPoint(latitude: 41.6083, longitude: 2.2876),
    'mataro': GeoPoint(latitude: 41.5381, longitude: 2.4447),
    'manresa': GeoPoint(latitude: 41.7251, longitude: 1.8266),
    'vic': GeoPoint(latitude: 41.9301, longitude: 2.2549),
    'igualada': GeoPoint(latitude: 41.5781, longitude: 1.6172),
    'girona': GeoPoint(latitude: 41.9794, longitude: 2.8214),
    'figueres': GeoPoint(latitude: 42.2662, longitude: 2.9614),
    'olot': GeoPoint(latitude: 42.1822, longitude: 2.4890),
    'lleida': GeoPoint(latitude: 41.6176, longitude: 0.6200),
    'tarragona': GeoPoint(latitude: 41.1189, longitude: 1.2445),
    'reus': GeoPoint(latitude: 41.1561, longitude: 1.1069),
    'tortosa': GeoPoint(latitude: 40.8125, longitude: 0.5216),
    'sitges': GeoPoint(latitude: 41.2370, longitude: 1.8059),
    'vilanova i la geltru': GeoPoint(latitude: 41.2242, longitude: 1.7256),
  };

  @override
  Future<GeoPoint?> findMunicipality(String name) async {
    return _municipalities[_normalize(name)];
  }

  /// Minúscules i sense accents, perquè «Mataró» i «mataro» coincideixin.
  static String _normalize(String name) {
    const accents = {
      'à': 'a', 'á': 'a', 'è': 'e', 'é': 'e', 'í': 'i', 'ï': 'i', //
      'ò': 'o', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ç': 'c', '’': "'",
    };
    final lower = name.trim().toLowerCase();
    return [for (final char in lower.split('')) accents[char] ?? char].join();
  }
}
