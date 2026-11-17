import '../models/activity.dart';
import '../models/geo_point.dart';
import '../models/new_activity.dart';

/// Converteix un objecte JSON d'esdeveniment del backend (en `kebab-case`)
/// al model de domini [Activity] (en `camelCase`).
Activity activityFromJson(Map<String, Object?> json) {
  final rawId = json['id'];
  final id = rawId is int ? rawId.toString() : _text(rawId);
  final title = _text(json['title']);
  final rawDate = _text(json['start-date']);
  if (id == null ||
      (int.tryParse(id) ?? 0) < 1 ||
      title == null ||
      rawDate == null) {
    throw const FormatException('An event needs an ID, title and start date');
  }
  final date = DateTime.tryParse(rawDate);
  if (date == null) throw const FormatException('Invalid event start date');
  final startsAt = DateTime(
    date.year,
    date.month,
    date.day,
    date.hour,
    date.minute,
  );
  // Sense data de fi, el backend hi desa la d'inici: aleshores no n'hi ha.
  final rawEnd = DateTime.tryParse(_text(json['end-date']) ?? '');
  final endsAt = rawEnd == null
      ? null
      : DateTime(
          rawEnd.year,
          rawEnd.month,
          rawEnd.day,
          rawEnd.hour,
          rawEnd.minute,
        );
  final image = _cover(json['image-url']) ?? _cover(json['images']);
  final rawCategories = json['categories'] ?? json['category'];
  final tags = rawCategories is List
      ? rawCategories.whereType<String>()
      : [if (rawCategories is String) rawCategories];
  // TODO(DP-046): Choose the badge only after removing labels without a name.
  final categories = List<String>.unmodifiable(
    tags
        .map(activityCategoryLabel)
        .where((label) => label.trim().isNotEmpty)
        .toSet(),
  );
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
    id: id,
    title: title,
    category: categories.firstOrNull ?? 'Activitat',
    categories: categories,
    municipality: _municipality(json['municipality']) ?? place ?? '',
    // The backend stores civil dates; preserve its calendar fields (DP-029).
    startsAt: startsAt,
    endsAt: endsAt != null && endsAt.isAfter(startsAt) ? endsAt : null,
    imageAsset: image?.asset ?? '',
    imageUrl: image?.url,
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
    schedule: _text(json['schedule']),
    modality: _modalityFromJson[_text(json['modality'])],
    isPermanent: json['permanent'] == true,
    onlineUrl: _url(json['activity-url']),
    website: _url(json['url']),
    links: _links(json['related-urls'], json['url-names']),
    tickets: _text(json['tickets']),
    ticketsUrl: _url(json['tickets-url']),
    email: _text(json['email']),
    phone: _text(json['phone']),
  );
}

/// Valors de `modality` al backend (un `enum` de la base de dades).
// TODO(DP-051): no hi ha contracte escrit; són els valors de l'`enum`.
const _modalityToJson = {
  ActivityModality.inPerson: 'Face-to-Face',
  ActivityModality.online: 'Online',
  ActivityModality.mixed: 'Online and Face-to-Face',
};
final _modalityFromJson = {
  for (final MapEntry(:key, :value) in _modalityToJson.entries) value: key,
};

/// Només adreces web completes; la resta no es pot obrir ni copiar com a
/// enllaç.
String? _url(Object? value) {
  final text = _text(value);
  final uri = text == null ? null : Uri.tryParse(text);
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
    return null;
  }
  return uri.host.isEmpty ? null : text;
}

/// `related-urls` i `url-names` són dues llistes separades per comes. Les
/// adreces se separen davant de cada `http`; si els noms no hi quadren (un nom
/// també pot portar comes), es fa servir el domini com a nom.
List<ActivityLink> _links(Object? rawUrls, Object? rawNames) {
  final urls = [
    for (final part in (_text(rawUrls) ?? '').split(
      RegExp(r',\s*(?=https?://)'),
    ))
      ?_url(part),
  ];
  final names = (_text(rawNames) ?? '')
      .split(',')
      .map((name) => name.trim())
      .toList();
  final namesMatch = names.length == urls.length;
  return [
    for (final (index, url) in urls.indexed)
      ActivityLink(
        name: namesMatch && names[index].isNotEmpty
            ? names[index]
            : Uri.parse(url).host.replaceFirst(RegExp(r'^www\.'), ''),
        url: url,
      ),
  ];
}

/// Converteix un [NewActivity] al cos JSON en `kebab-case` que espera `POST /events`.
// TODO(DP-017): el preu, la imatge i l'hora no es desen al backend.
Map<String, Object?> newActivityToJson(NewActivity activity) {
  final startDate = _wallClockAsUtc(activity.startsAt).toIso8601String();
  return <String, Object?>{
    'title': activity.title,
    'description': activity.description,
    // L'etiqueta del backend (`agenda:categories/teatre`): amb un nom que no
    // existeix, el backend en crearia una categoria nova.
    'categories': activity.categories,
    'municipality': activity.municipality,
    // En llegir-la, lloc i adreça s'ajunten com a indicacions: si totes dues
    // portessin el mateix text, sortiria repetit.
    'address': activity.directions ?? '',
    'start-date': startDate,
    // Sense data de fi, l'activitat acaba el mateix dia que comença.
    'end-date': switch (activity.endsAt) {
      final endsAt? => _wallClockAsUtc(endsAt).toIso8601String(),
      null => startDate,
    },
    // (0, 0) vol dir sense ubicació.
    'latitude': activity.location?.latitude ?? 0.0,
    'longitude': activity.location?.longitude ?? 0.0,
    // Sense preu no se sap si és gratuïta.
    if (activity.price case final price?) 'free': price == 0,
    // El backend només desa el dia: l'hora es llegeix de l'«Horari».
    'schedule': activity.schedule ?? '',
    'modality': _modalityToJson[activity.modality],
    'permanent': activity.isPermanent,
    'activity-url': activity.onlineUrl ?? '',
    'is-official': false,
  };
}

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

({String asset, String? url})? _cover(Object? value) {
  final raw = _text(value);
  if (raw == null) return null;
  if (raw.startsWith('assets/')) return (asset: raw, url: null);
  // Gencat separates covers with commas and can return /content/dam/ paths.
  // TODO(DP-037): Prefer absolute image URLs from the API when available.
  for (final candidate in raw.split(
    RegExp(r',\s*(?=https?://|/content/dam/)'),
  )) {
    var uri = Uri.tryParse(candidate.trim());
    if (uri == null) continue;
    if (candidate.trim().startsWith('/content/dam/')) {
      uri = Uri.https('agenda.cultura.gencat.cat', '/').resolveUri(uri);
    }
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty) {
      return (asset: '', url: uri.toString());
    }
  }
  return null;
}

String activityCategoryLabel(String tag) =>
    _capitalize(tag.trim().split('/').last.replaceAll('-', ' '));

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
