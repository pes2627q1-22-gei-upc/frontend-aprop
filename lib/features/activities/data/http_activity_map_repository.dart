import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/activity.dart';
import '../models/geo_bounds.dart';
import '../models/geo_point.dart';
import '../repositories/activity_map_repository.dart';

/// Activitats del mapa d'Inici des del backend: `GET /events/map` amb la zona
/// visible i `GET /events/{id}` per a la fitxa que s'obre des del mapa.
// TODO(DP-029): `GET /events/map` és a la branca `feature/events-map`
// d'api-aprop, sense fusionar: el contracte encara pot canviar.
class HttpActivityMapRepository implements ActivityMapRepository {
  HttpActivityMapRepository({
    required this.baseUrl,
    this._idToken,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final Uri baseUrl;

  /// Token de la sessió per a `Authorization: Bearer`: el backend el demana a
  /// totes les rutes. Sense token (dades de demostració) no s'envia.
  final Future<String?> Function()? _idToken;

  final http.Client _client;
  final Duration timeout;

  @override
  Future<List<Activity>> getActivitiesInArea(GeoBounds area) async {
    final response = await _get('events/map', {
      'minLat': '${area.southWest.latitude}',
      'maxLat': '${area.northEast.latitude}',
      'minLng': '${area.southWest.longitude}',
      'maxLng': '${area.northEast.longitude}',
    });
    if (response.statusCode != 200) throw _unexpected(response);

    final events = _decode(response) as List<Object?>;
    return [
      for (final event in events) _activityFrom(event as Map<String, Object?>),
    ];
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    // Els ID del backend són números: un altre ID no hi pot existir.
    if (int.tryParse(id) == null) return null;

    final response = await _get('events/$id');
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw _unexpected(response);

    return _activityFrom(_decode(response) as Map<String, Object?>);
  }

  /// Accepta la URL base amb barra final o sense.
  Future<http.Response> _get(String path, [Map<String, String>? query]) async {
    final base = baseUrl.toString().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/$path').replace(queryParameters: query);
    final token = await _idToken?.call();
    return _client
        .get(
          uri,
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        )
        .timeout(timeout);
  }

  /// El backend no indica el joc de caràcters i `response.body` llegiria els
  /// accents com a Latin-1.
  Object? _decode(http.Response response) =>
      jsonDecode(utf8.decode(response.bodyBytes));

  StateError _unexpected(http.Response response) => StateError(
    'GET ${response.request?.url.path} ha respost ${response.statusCode}',
  );
}

Activity _activityFrom(Map<String, Object?> json) {
  // `is-official` només el dona `GET /events/map`. A la fitxa, les activitats
  // oficials són les que tenen el codi de l'Agenda Cultural.
  final isOfficial =
      json['is-official'] as bool? ?? (json['code'] as num? ?? 0) != 0;
  final latitude = (json['latitude'] as num?)?.toDouble() ?? 0;
  final longitude = (json['longitude'] as num?)?.toDouble() ?? 0;
  final place = _text(json['place']);
  final address = _text(json['address']);
  final directions = [?place, ?address].join(' · ');

  return Activity(
    id: '${json['id']}',
    title: json['title'] as String? ?? '',
    category: _category(json['categories']),
    municipality: _municipality(json['municipality']) ?? place ?? '',
    startsAt: _day(json['start-date'] as String),
    // TODO(DP-029): el backend dona rutes d'imatge de l'Agenda Cultural sense
    // domini. Mentrestant, les targetes mostren la imatge per defecte.
    imageAsset: '',
    source: isOfficial
        ? ActivitySource.culturalAgenda
        : ActivitySource.community,
    // TODO(DP-029): el backend només dona l'UUID de qui l'ha creada.
    creator: isOfficial
        ? null
        : const ActivityCreator(name: 'un usuari', isFriend: false),
    description: _text(json['description']),
    directions: directions.isEmpty ? null : directions,
    // (0, 0) vol dir que l'Agenda Cultural no en té les coordenades.
    location: latitude == 0 && longitude == 0
        ? null
        : GeoPoint(latitude: latitude, longitude: longitude),
    price: json['free'] == true ? 0 : null,
  );
}

String? _text(Object? value) {
  final text = (value as String?)?.trim();
  return text == null || text.isEmpty ? null : text;
}

/// El backend desa només el dia, a les 00.00 UTC (DP-029): es llegeix com un
/// dia d'aquí, sense passar-lo a l'hora local.
DateTime _day(String value) {
  final date = DateTime.parse(value);
  return DateTime(date.year, date.month, date.day, date.hour, date.minute);
}

/// `agenda:categories/arts-visuals` → «Arts visuals».
// TODO(DP-029): les etiquetes no porten accents («Musica») i el mapa no en
// rep cap.
String _category(Object? categories) {
  final tag = categories is List
      ? categories.whereType<String>().where((c) => c.isNotEmpty).firstOrNull
      : null;
  if (tag == null) return 'Activitat';
  return _capitalize(tag.split('/').last.replaceAll('-', ' '));
}

const _lowercaseWords = {'de', 'del', 'dels', 'la', 'les', 'el', 'els', 'i'};

/// `agenda:ubicacions/barcelona/baix-llobregat/sant-andreu-de-la-barca` →
/// «Sant Andreu de la Barca». `l-hospitalet` → «L’Hospitalet».
// TODO(DP-029): l'etiqueta no porta accents («Tarrega»): caldria el nom del
// municipi des del backend.
String? _municipality(Object? tag) {
  final slug = _text(tag)?.split('/').last;
  if (slug == null) return null;

  final words = slug.split('-').where((w) => w.isNotEmpty).toList();
  final name = StringBuffer();
  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    final elided = (word == 'l' || word == 'd') && i + 1 < words.length;
    final keepLowercase = i > 0 && (elided || _lowercaseWords.contains(word));
    name.write(keepLowercase ? word : _capitalize(word));
    if (i + 1 < words.length) name.write(elided ? '’' : ' ');
  }
  return name.toString();
}

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
