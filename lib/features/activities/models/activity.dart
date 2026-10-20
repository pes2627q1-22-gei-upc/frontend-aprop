import 'geo_point.dart';

enum ActivitySource { culturalAgenda, community }

class ActivityCreator {
  const ActivityCreator({
    required this.name,
    required this.isFriend,
    this.avatarAsset,
  });

  final String name;
  final bool isFriend;

  /// Nul si la persona no té foto (per exemple, qui crea una activitat des de
  /// l'app): es mostra una icona.
  final String? avatarAsset;
}

class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.category,
    required this.municipality,
    required this.startsAt,
    required this.imageAsset,
    required this.source,
    this.creator,
    this.description,
    this.directions,
    this.location,
    this.price,
  });

  final String id;
  final String title;
  final String category;
  final String municipality;
  final DateTime startsAt;
  final String imageAsset;
  final ActivitySource source;
  final ActivityCreator? creator;
  final String? description;

  /// Indicacions per arribar-hi, com «entrada pel pati, 2n pis».
  final String? directions;

  /// Punt exacte al mapa, si se sap.
  final GeoPoint? location;

  /// En euros. `0` vol dir gratuïta; nul vol dir que no se sap.
  final double? price;
}
