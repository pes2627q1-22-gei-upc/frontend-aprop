// Pure-Dart category normalization and trilingual (ca/es/en) label dictionary.
// Kept in models/ with no Flutter dependency so models, mappers, filters,
// ViewModels and widgets can share the exact same rules.
// TODO(DP-081): Static frontend dictionary derived from Gencat Agenda Cultural
// (`tags_categor_es` and `tags_mbits`) until the backend exposes localized
// category labels.

/// Trilingual display labels for a known cultural category.
typedef _LocalizedCategory = ({String ca, String es, String en});

/// Known category keys from the Generalitat Agenda Cultural dataset
/// (`agenda:categories/*`, `agenda:ambits/*`), demo filter options, and the
/// uncategorised fallback (`activitat`).
const Map<String, _LocalizedCategory> _categoryLabels = {
  'activitat': (ca: 'Activitat', es: 'Actividad', en: 'Activity'),
  'activitats-virtuals': (
    ca: 'Activitats virtuals',
    es: 'Actividades virtuales',
    en: 'Online activities',
  ),
  'altres-ambits': (
    ca: 'Altres àmbits',
    es: 'Otros ámbitos',
    en: 'Other fields',
  ),
  'any-europeu-patrimoni': (
    ca: 'Any Europeu del Patrimoni',
    es: 'Año Europeo del Patrimonio',
    en: 'European Year of Heritage',
  ),
  'any-gaudi': (ca: 'Any Gaudí', es: 'Año Gaudí', en: 'Gaudí Year'),
  'arts-visuals': (ca: 'Arts visuals', es: 'Artes visuales', en: 'Visual arts'),
  'carnavals': (ca: 'Carnavals', es: 'Carnavales', en: 'Carnivals'),
  'cicles': (ca: 'Cicles', es: 'Ciclos', en: 'Series'),
  'cinema': (ca: 'Cinema', es: 'Cine', en: 'Cinema'),
  'circ': (ca: 'Circ', es: 'Circo', en: 'Circus'),
  'commemoracions': (
    ca: 'Commemoracions',
    es: 'Conmemoraciones',
    en: 'Commemorations',
  ),
  'concerts': (ca: 'Concerts', es: 'Conciertos', en: 'Concerts'),
  'conferencies': (ca: 'Conferències', es: 'Conferencias', en: 'Conferences'),
  'cultura-digital': (
    ca: 'Cultura digital',
    es: 'Cultura digital',
    en: 'Digital culture',
  ),
  'cultura-popular': (
    ca: 'Cultura popular',
    es: 'Cultura popular',
    en: 'Popular culture',
  ),
  'cursos': (ca: 'Cursos', es: 'Cursos', en: 'Courses'),
  'dansa': (ca: 'Dansa', es: 'Danza', en: 'Dance'),
  'divulgacio': (ca: 'Divulgació', es: 'Divulgación', en: 'Outreach'),
  'espectacles': (ca: 'Espectacles', es: 'Espectáculos', en: 'Performing arts'),
  'exposicions': (ca: 'Exposicions', es: 'Exposiciones', en: 'Exhibitions'),
  'festes': (ca: 'Festes', es: 'Fiestas', en: 'Festivities'),
  'festivals-i-mostres': (
    ca: 'Festivals i mostres',
    es: 'Festivales y muestras',
    en: 'Festivals & showcases',
  ),
  'fires-i-mercats': (
    ca: 'Fires i mercats',
    es: 'Ferias y mercados',
    en: 'Fairs & markets',
  ),
  'gastronomia': (ca: 'Gastronomia', es: 'Gastronomía', en: 'Gastronomy'),
  'gegants': (ca: 'Gegants', es: 'Gigantes', en: 'Giants'),
  'infantil': (ca: 'Infantil', es: 'Infantil', en: 'Children'),
  'llibres-i-lletres': (
    ca: 'Llibres i lletres',
    es: 'Libros y letras',
    en: 'Books & literature',
  ),
  'magia': (ca: 'Màgia', es: 'Magia', en: 'Magic'),
  'musica': (ca: 'Música', es: 'Música', en: 'Music'),
  'nadal': (ca: 'Nadal', es: 'Navidad', en: 'Christmas'),
  'opera': (ca: 'Òpera', es: 'Ópera', en: 'Opera'),
  'rutes-i-visites': (
    ca: 'Rutes i visites',
    es: 'Rutas y visitas',
    en: 'Tours & visits',
  ),
  'sardanes': (ca: 'Sardanes', es: 'Sardanas', en: 'Sardanes'),
  'setmana-santa': (ca: 'Setmana Santa', es: 'Semana Santa', en: 'Easter'),
  'teatre': (ca: 'Teatre', es: 'Teatro', en: 'Theatre'),
  'tradicional-i-popular': (
    ca: 'Tradicional i popular',
    es: 'Tradicional y popular',
    en: 'Traditional & folk',
  ),
};

/// Reverse index mapping any normalized known label (in ca, es or en) back to
/// its canonical slug so filtering, matching and re-localization remain
/// consistent across language switches.
final Map<String, String> _reverseLabelLookup = {
  for (final MapEntry(:key, :value) in _categoryLabels.entries) ...{
    key: key,
    _toSlug(value.ca): key,
    _toSlug(value.es): key,
    _toSlug(value.en): key,
  },
};

/// Leading Gencat sort-key prefixes such as `zz-`, `za-`, `zz `, `Zz `.
final _sortKeyPrefix = RegExp(r'^z[a-z]?[-_\s]+(?=\S)', caseSensitive: false);

/// Short connectors kept lowercase inside multi-word fallback titles.
const _lowercaseConnectors = {
  'a',
  'al',
  'als',
  'and',
  'd',
  'de',
  'del',
  'dels',
  'el',
  'els',
  'en',
  'for',
  'i',
  'in',
  'l',
  'la',
  'las',
  'les',
  'los',
  'of',
  'per',
  'the',
  'y',
};

/// Strips namespace/path prefixes (`agenda:categories/`, `agenda:ambits/`,
/// `namespace:`) and leading sort-key prefixes (`zz-`, `za-`, `zz `).
/// Returns an empty string when no usable category name remains.
String _stripCategoryPrefixes(String raw) {
  var segment = raw.trim();
  if (segment.isEmpty) return '';
  if (segment.contains('/')) {
    segment = segment.split('/').last.trim();
    if (segment.isEmpty) return '';
  }
  if (segment.contains(':')) {
    segment = segment.split(':').last.trim();
    if (segment.isEmpty) return '';
  }
  segment = segment.replaceFirst(_sortKeyPrefix, '').trim();
  return segment;
}

/// Converts a clean segment into a lowercase ASCII hyphenated slug.
String _toSlug(String value) =>
    _foldDiacritics(value)
        .toLowerCase()
        .replaceAll('&', ' ')
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

String _foldDiacritics(String value) => value
    .replaceAll(RegExp('[àáâäãåÀÁÂÄÃÅ]'), 'a')
    .replaceAll(RegExp('[èéêëÈÉÊË]'), 'e')
    .replaceAll(RegExp('[ìíîïÌÍÎÏ]'), 'i')
    .replaceAll(RegExp('[òóôöõÒÓÔÖÕ]'), 'o')
    .replaceAll(RegExp('[ùúûüÙÚÛÜ]'), 'u')
    .replaceAll(RegExp('[çÇ]'), 'c')
    .replaceAll(RegExp('[ñÑ]'), 'n')
    .replaceAll(RegExp('[\u0300-\u036f]'), '');

/// Canonical language-independent key for any raw backend tag, Catalan name,
/// or localized label (e.g. `'agenda:ambits/espectacles'`, `'Espectacles'`,
/// `'Espectáculos'` and `'Performing arts'` all resolve to `'espectacles'`).
String canonicalActivityCategoryKey(String raw) {
  final cleaned = _stripCategoryPrefixes(raw);
  if (cleaned.isEmpty) return '';
  final slug = _toSlug(cleaned);
  if (slug.isEmpty) return '';
  return _reverseLabelLookup[slug] ?? slug;
}

/// Whether [value] represents a missing or generic uncategorised fallback
/// (`''`, `'Activitat'`, `'Actividad'`, `'Activity'`).
bool isUncategorizedActivityCategory(String value) {
  final key = canonicalActivityCategoryKey(value);
  return key.isEmpty || key == 'activitat';
}

/// Returns the user-facing category label in [languageCode] (`'ca'`, `'es'`,
/// `'en'`; defaults to Catalan).
///
/// Known keys come from the per-language dictionary with proper accents and
/// capitalisation. Unknown keys fall back to a prettified version (namespace
/// and sort-key prefixes stripped, separators replaced by spaces, title-cased).
String localizeActivityCategory(String raw, {String languageCode = 'ca'}) {
  final cleaned = _stripCategoryPrefixes(raw);
  if (cleaned.isEmpty) return '';
  final key = canonicalActivityCategoryKey(cleaned);
  final entry = _categoryLabels[key];
  if (entry != null) {
    final normalizedLang = languageCode
        .trim()
        .toLowerCase()
        .split(RegExp(r'[-_]'))
        .first;
    return switch (normalizedLang) {
      'es' => entry.es,
      'en' => entry.en,
      _ => entry.ca,
    };
  }
  return _prettifyUnknownCategory(cleaned);
}

String _prettifyUnknownCategory(String cleaned) {
  final words = cleaned
      .replaceAll(RegExp(r'[-_]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '';
  final buffer = StringBuffer();
  for (var i = 0; i < words.length; i++) {
    final lower = words[i].toLowerCase();
    if (i > 0 && _lowercaseConnectors.contains(lower)) {
      buffer.write(lower);
    } else {
      buffer.write(lower[0].toUpperCase());
      buffer.write(lower.substring(1));
    }
    if (i + 1 < words.length) buffer.write(' ');
  }
  return buffer.toString();
}

/// Accent- and case-insensitive comparator for sorting displayed category
/// labels alphabetically in any supported language.
int compareActivityCategoryLabels(String a, String b) {
  final foldedA = _foldDiacritics(a).toLowerCase();
  final foldedB = _foldDiacritics(b).toLowerCase();
  final primary = foldedA.compareTo(foldedB);
  return primary != 0 ? primary : a.compareTo(b);
}

/// Deduplicates [categories] by canonical key (preserving order) and, when
/// [activeFilterCategories] is non-empty, moves categories matching the active
/// filter to the front so event cards surface the filtered category first.
List<String> orderActivityCategoriesForFilter(
  Iterable<String> categories, [
  Iterable<String> activeFilterCategories = const [],
]) {
  final seen = <String>{};
  final unique = <String>[];
  for (final category in categories) {
    final key = canonicalActivityCategoryKey(category);
    if (key.isEmpty || !seen.add(key)) continue;
    unique.add(category);
  }
  if (unique.length <= 1) return List.unmodifiable(unique);

  final activeKeys = {
    for (final filter in activeFilterCategories)
      if (canonicalActivityCategoryKey(filter) case final key
          when key.isNotEmpty)
        key,
  };
  if (activeKeys.isEmpty) return List.unmodifiable(unique);

  final matching = <String>[];
  final others = <String>[];
  for (final category in unique) {
    if (activeKeys.contains(canonicalActivityCategoryKey(category))) {
      matching.add(category);
    } else {
      others.add(category);
    }
  }
  if (matching.isEmpty) return List.unmodifiable(unique);
  return List.unmodifiable([...matching, ...others]);
}
