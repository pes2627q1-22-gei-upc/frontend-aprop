import '../models/activity.dart';
import '../models/geo_point.dart';
import '../models/new_activity.dart';

/// Converteix un objecte JSON d'esdeveniment del backend (en `kebab-case`)
/// al model de domini [Activity] (en `camelCase`).
Activity activityFromJson(Map<String, Object?> json) {
  final isOfficial =
      json['is-official'] as bool? ?? (json['code'] as num? ?? 0) != 0;
  final latitude = (json['latitude'] as num?)?.toDouble() ?? 0;
  final longitude = (json['longitude'] as num?)?.toDouble() ?? 0;
  final place = _text(json['place']);
  final address = _text(json['address']);
  final directions = <String>[
    ?place,
    if (address != null && address != place) address,
  ].join(' · ');

  final creatorUuid = _text(json['creator']);
  final creatorName = _text(json['creator-name']) ?? 'un usuari';
  final hasFriends = json['has-friends'] as bool? ?? false;

  final rawPrice = json['price'];
  final double? price = switch (rawPrice) {
    final num n => n.toDouble(),
    _ => json['free'] == true ? 0 : null,
  };

  return Activity(
    id: '${json['id']}',
    title: json['title'] as String? ?? '',
    category: _category(json['categories'] ?? json['category']),
    municipality: _municipality(json['municipality']) ?? place ?? '',
    startsAt: _parseDate(json['start-date'] as String?),
    imageAsset: _imageAsset(json['image-url'] ?? json['images']),
    source: isOfficial
        ? ActivitySource.culturalAgenda
        : ActivitySource.community,
    creator: isOfficial
        ? null
        : ActivityCreator(
            name: creatorName,
            userId: creatorUuid,
            isFriend: hasFriends,
          ),
    description: _text(json['description']),
    directions: directions.isEmpty ? null : directions,
    location: latitude == 0 && longitude == 0
        ? null
        : GeoPoint(latitude: latitude, longitude: longitude),
    price: price,
  );
}

/// Converteix un [NewActivity] al cos JSON en `kebab-case` que espera `POST /events`.
// TODO(DP-017): el preu, la imatge i l'hora no es desen al backend.
Map<String, Object?> newActivityToJson(NewActivity activity) {
  final isoDate = _wallClockAsUtc(activity.startsAt).toIso8601String();
  return <String, Object?>{
    'title': activity.title,
    'description': activity.description,
    // L'etiqueta del backend (`agenda:categories/teatre`): amb un nom que no
    // existeix, el backend en crearia una categoria nova.
    'categories': <String>[activity.category],
    'municipality': activity.municipality,
    // En llegir-la, lloc i adreça s'ajunten com a indicacions: si totes dues
    // portessin el mateix text, sortiria repetit.
    'address': activity.directions ?? '',
    'start-date': isoDate,
    'end-date': isoDate,
    // (0, 0) vol dir sense ubicació.
    'latitude': activity.location?.latitude ?? 0.0,
    'longitude': activity.location?.longitude ?? 0.0,
    // Sense preu no se sap si és gratuïta.
    if (activity.price case final price?) 'free': price == 0,
    'is-official': false,
  };
}

/// Nom que es mostra d'una etiqueta de categoria del backend:
/// `agenda:categories/arts-visuals` → «Arts visuals».
String activityCategoryLabel(String tag) => _category(tag);

/// El backend desa només el dia, en UTC: passar l'hora d'aquí a UTC podria
/// canviar-lo (les 00.30 h d'aquí són el dia anterior en UTC). Es llegeix igual
/// a `_parseDate`, sense canviar de zona.
// TODO(DP-029): sobrarà quan el backend desi també l'hora.
DateTime _wallClockAsUtc(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day, date.hour, date.minute);

String? _text(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String _imageAsset(Object? value) {
  final raw = _text(value);
  if (raw == null) return '';
  if (raw.startsWith('assets/')) return raw;
  return '';
}

DateTime _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return DateTime(2026, 1, 1);
  }
  final date = DateTime.parse(value);
  return DateTime(date.year, date.month, date.day, date.hour, date.minute);
}

String _category(Object? categories) {
  if (categories is String && categories.trim().isNotEmpty) {
    return _capitalize(categories.trim().split('/').last.replaceAll('-', ' '));
  }
  final tag = categories is List
      ? categories.whereType<String>().where((c) => c.isNotEmpty).firstOrNull
      : null;
  if (tag == null) return 'Activitat';
  return _capitalize(tag.split('/').last.replaceAll('-', ' '));
}

const _lowercaseWords = {'de', 'del', 'dels', 'la', 'les', 'el', 'els', 'i'};

String? _municipality(Object? tag) {
  final raw = _text(tag);
  if (raw == null) return null;
  if (!raw.contains('/') && !raw.contains('-')) {
    return raw;
  }
  final slug = raw.split('/').last;
  if (slug.isEmpty) return null;

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
