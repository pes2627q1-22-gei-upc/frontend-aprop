import 'geo_point.dart';

enum ActivitySource { culturalAgenda, community }

/// Si l'activitat es fa en un lloc, en línia o de les dues maneres.
enum ActivityModality { inPerson, online, mixed }

/// Enllaç amb més informació, amb el nom que es mostra.
class ActivityLink {
  const ActivityLink({required this.name, required this.url});

  final String name;
  final String url;
}

class ActivityCreator {
  const ActivityCreator({
    required this.name,
    required this.isFriend,
    this.avatarAsset,
    this.userId,
  });

  final String name;
  final bool isFriend;

  /// Stable ownership identity when supplied; a display name is not unique.
  final String? userId;

  /// Nul si la persona no té foto (per exemple, qui crea una activitat des de
  /// l'app): es mostra una icona.
  final String? avatarAsset;
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
    this.endsAt,
    this.description,
    this.directions,
    this.location,
    this.price,
    this.imageUrl,
    this.schedule,
    this.modality,
    this.isPermanent = false,
    this.onlineUrl,
    this.website,
    Iterable<ActivityLink> links = const [],
    this.tickets,
    this.ticketsUrl,
    this.email,
    this.phone,
    Iterable<String> categories = const [],
  }) : links = List.unmodifiable(links),
       categories = List.unmodifiable(
         categories.isEmpty ? [category] : categories,
       );

  final String id;
  final String title;
  final String category;

  /// All reported categories participate in filtering, not just the badge.
  final List<String> categories;
  final String municipality;
  final DateTime startsAt;

  /// Fi de l'activitat, si n'hi ha i no és el mateix moment que l'inici.
  final DateTime? endsAt;
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

  /// L'«Horari» tal com es publica: «19 h», «A les 10 h. Durada: 1 h»... El
  /// backend només desa el dia de l'inici (DP-029): l'hora és aquí.
  final String? schedule;

  /// Nul si no se sap.
  final ActivityModality? modality;

  /// Activitat sense data de fi, com una exposició fixa.
  final bool isPermanent;

  /// On es connecta qui la segueix en línia.
  final String? onlineUrl;

  /// Web de l'activitat.
  final String? website;

  /// Altres enllaços amb més informació.
  final List<ActivityLink> links;

  /// Informació d'entrades i inscripció, com «Places limitades».
  final String? tickets;
  final String? ticketsUrl;

  /// Contacte de qui l'organitza. Només el porten les de l'Agenda Cultural:
  /// a les no oficials no es demana (dades personals).
  final String? email;
  final String? phone;
}
