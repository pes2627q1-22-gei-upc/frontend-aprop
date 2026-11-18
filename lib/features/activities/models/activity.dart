import 'geo_point.dart';

enum ActivitySource { culturalAgenda, community }

class ActivityCreator {
  const ActivityCreator({
    required this.name,
    required this.isFriend,
    this.avatarAsset,
    this.userId,
    this.reliability,
  });

  final String name;
  final bool isFriend;

  /// Stable ownership identity when supplied; a display name is not unique.
  final String? userId;

  /// Nul si la persona no té foto (per exemple, qui crea una activitat des de
  /// l'app): es mostra una icona.
  final String? avatarAsset;

  /// Mitjana 0–5 de les valoracions de l'organitzador; nul si no en té.
  final double? reliability;
}

class Activity {
  Activity({
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
    this.imageUrl,
    Iterable<String> categories = const [],
  }) : categories = List.unmodifiable(
         categories.isEmpty ? [category] : categories,
       );

  final String id;
  final String title;
  final String category;

  /// All reported categories participate in filtering, not just the badge.
  final List<String> categories;
  final String municipality;
  final DateTime startsAt;
  final String imageAsset;

  /// Remote cover when supplied by the server; demo assets remain independent.
  final String? imageUrl;
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
