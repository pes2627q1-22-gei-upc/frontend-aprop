import 'activity.dart';
import 'geo_point.dart';

/// Dades d'una activitat no oficial que un usuari vol publicar. El repositori
/// en crea l'[Activity] amb el seu ID.
class NewActivity {
  NewActivity({
    required this.title,
    required this.description,
    required List<String> categories,
    required this.startsAt,
    required this.imageAsset,
    required this.creator,
    this.municipality = '',
    this.endsAt,
    this.directions,
    this.location,
    this.price,
    this.schedule,
    this.modality = ActivityModality.inPerson,
    this.isPermanent = false,
    this.onlineUrl,
  }) : assert(categories.isNotEmpty),
       categories = List.unmodifiable(categories);

  final String title;
  final String description;

  /// Valors de les categories triades (entre 1 i 3).
  final List<String> categories;

  /// La primera, la que fa de distintiu.
  String get category => categories.first;

  final DateTime startsAt;

  /// Fi de l'activitat, si s'ha indicat. És posterior a [startsAt].
  final DateTime? endsAt;

  /// Buit si no se n'ha indicat cap: el municipi és opcional.
  final String municipality;
  final String imageAsset;
  final ActivityCreator creator;

  /// Indicacions per arribar-hi, com «entrada pel pati, 2n pis».
  final String? directions;

  /// Punt exacte al mapa, si se sap.
  final GeoPoint? location;

  /// En euros; `0` vol dir gratuïta.
  final double? price;

  /// L'«Horari» que es desa: el genera el formulari a partir de les hores.
  final String? schedule;
  final ActivityModality modality;
  final bool isPermanent;

  /// On es connecta qui la segueix en línia.
  final String? onlineUrl;
}
