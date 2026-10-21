/// Centre aproximat de Catalunya, per quan encara no se sap on és el lloc.
const cataloniaCenter = GeoPoint(latitude: 41.8204, longitude: 1.8676);

/// Punt geogràfic (graus decimals). No depèn de cap paquet de mapes.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}
