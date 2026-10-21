import 'activity.dart';
import 'geo_point.dart';

/// Dades d'una activitat no oficial que un usuari vol publicar. El repositori
/// en crea l'[Activity] amb el seu ID.
class NewActivity {
  const NewActivity({
    required this.title,
    required this.description,
    required this.category,
    required this.startsAt,
    required this.municipality,
    required this.imageAsset,
    required this.creator,
    this.directions,
    this.location,
    this.price,
  });

  final String title;
  final String description;
  final String category;
  final DateTime startsAt;
  final String municipality;
  final String imageAsset;
  final ActivityCreator creator;

  /// Indicacions per arribar-hi, com «entrada pel pati, 2n pis».
  final String? directions;

  /// Punt exacte al mapa, si se sap.
  final GeoPoint? location;

  /// En euros; `0` vol dir gratuïta.
  final double? price;
}
