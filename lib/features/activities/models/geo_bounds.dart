import 'geo_point.dart';

/// Rectangle geogràfic, com la zona visible del mapa. No depèn de cap paquet de
/// mapes.
class GeoBounds {
  const GeoBounds({required this.southWest, required this.northEast});

  final GeoPoint southWest;
  final GeoPoint northEast;

  /// Cert si [other] queda sencer dins d'aquesta zona.
  bool contains(GeoBounds other) =>
      other.southWest.latitude >= southWest.latitude &&
      other.southWest.longitude >= southWest.longitude &&
      other.northEast.latitude <= northEast.latitude &&
      other.northEast.longitude <= northEast.longitude;

  /// La mateixa zona amb un marge de [fraction] de l'alçada i l'amplada a cada
  /// costat (0.5 la fa el doble d'alta i d'ampla).
  GeoBounds expandedBy(double fraction) {
    final latitudeMargin = (northEast.latitude - southWest.latitude) * fraction;
    final longitudeMargin =
        (northEast.longitude - southWest.longitude) * fraction;
    return GeoBounds(
      southWest: GeoPoint(
        latitude: (southWest.latitude - latitudeMargin).clamp(-90, 90),
        longitude: (southWest.longitude - longitudeMargin).clamp(-180, 180),
      ),
      northEast: GeoPoint(
        latitude: (northEast.latitude + latitudeMargin).clamp(-90, 90),
        longitude: (northEast.longitude + longitudeMargin).clamp(-180, 180),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GeoBounds &&
      other.southWest == southWest &&
      other.northEast == northEast;

  @override
  int get hashCode => Object.hash(southWest, northEast);

  @override
  String toString() => 'GeoBounds($southWest, $northEast)';
}
