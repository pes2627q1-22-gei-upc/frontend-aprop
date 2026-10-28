import '../../activities/models/activity.dart';
import '../../activities/repositories/activity_repository.dart';
import '../models/assistant_message.dart';
import '../repositories/assistant_repository.dart';

// TODO(DP-016): Replace with the backend assistant adapter once the Gemini endpoint contract is agreed.
class DemoAssistantRepository implements AssistantRepository {
  DemoAssistantRepository({
    required this._activityRepository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ActivityRepository _activityRepository;
  final DateTime Function() _clock;
  int _counter = 0;

  static const _knownMunicipalities = <String>[
    'Barcelona',
    'Girona',
    'Tarragona',
    'Lleida',
    'Manresa',
    'Sabadell',
    'Terrassa',
    'Reus',
    'Mataró',
  ];

  @override
  Future<AssistantMessage> sendMessage(String query) async {
    final catalogue = await _activityRepository.getActivities();
    final normalized = _normalize(query);

    final category = _extractCategory(normalized);
    final municipality = _extractMunicipality(normalized, catalogue);
    final dateFilter = _extractDateFilter(normalized);

    final interpretation = AssistantInterpretation(
      category: category,
      municipality: municipality,
      dateRange: dateFilter?.label,
    );

    final matches = catalogue
        .where((activity) {
          if (category != null &&
              _normalize(activity.category) != _normalize(category)) {
            return false;
          }
          if (municipality != null &&
              _normalize(activity.municipality) != _normalize(municipality)) {
            return false;
          }
          if (dateFilter != null && !dateFilter.matches(activity.startsAt)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    _counter += 1;
    final replyText = _buildReplyText(
      interpretation: interpretation,
      matches: matches,
    );

    return AssistantMessage.assistant(
      id: 'demo-assistant-$_counter',
      text: replyText,
      sentAt: _clock(),
      interpretation: interpretation.hasAny ? interpretation : null,
      recommendedActivities: matches,
    );
  }

  String _buildReplyText({
    required AssistantInterpretation interpretation,
    required List<Activity> matches,
  }) {
    final summaryParts = <String>[
      if (interpretation.category != null)
        'tipus: ${interpretation.category!.toLowerCase()}',
      if (interpretation.municipality != null)
        'municipi: ${interpretation.municipality}',
      if (interpretation.dateRange != null)
        'dates: ${interpretation.dateRange}',
    ];

    final criteriaPrefix = summaryParts.isEmpty
        ? ''
        : 'He interpretat la teva consulta (${summaryParts.join(' · ')}). ';

    if (matches.isEmpty) {
      return '${criteriaPrefix}No he trobat cap activitat que coincideixi amb aquests criteris. '
          'Pots provar amb un altre municipi, unes altres dates o un altre tipus d’activitat.';
    }

    if (!interpretation.hasAny) {
      return 'Aquí tens algunes propostes culturals destacades del catàleg. '
          'També em pots indicar el tipus d’activitat, el municipi o les dates.';
    }

    if (matches.length == 1) {
      return '${criteriaPrefix}He trobat 1 activitat que encaixa amb el que busques:';
    }

    return '${criteriaPrefix}He trobat ${matches.length} activitats que encaixen amb el que busques:';
  }

  String? _extractCategory(String normalizedQuery) {
    if (_containsAny(normalizedQuery, const [
      'musica',
      'musical',
      'jazz',
      'concert',
      'concerts',
    ])) {
      return 'Música';
    }
    if (_containsAny(normalizedQuery, const [
      'exposicio',
      'exposicions',
      'museu',
      'mirades',
      'art',
    ])) {
      return 'Exposicions';
    }
    if (_containsAny(normalizedQuery, const [
      'teatre',
      'obra',
      'escena',
      'estrelles',
    ])) {
      return 'Teatre';
    }
    if (_containsAny(normalizedQuery, const ['dansa', 'ball'])) {
      return 'Dansa';
    }
    if (_containsAny(normalizedQuery, const [
      'cinema',
      'pel·licula',
      'pellicula',
    ])) {
      return 'Cinema';
    }
    return null;
  }

  String? _extractMunicipality(
    String normalizedQuery,
    List<Activity> catalogue,
  ) {
    final candidates = <String>{
      ...catalogue.map((a) => a.municipality),
      ..._knownMunicipalities,
    };
    for (final candidate in candidates) {
      if (_containsWord(normalizedQuery, _normalize(candidate))) {
        return candidate;
      }
    }
    return null;
  }

  _DateFilter? _extractDateFilter(String normalizedQuery) {
    final has26 = _containsWord(normalizedQuery, '26');
    final has27 = _containsWord(normalizedQuery, '27');

    if ((has26 && has27) || normalizedQuery.contains('cap de setmana')) {
      return _DateFilter(
        label: '26–27 set. 2026',
        matches: (date) =>
            date.year == 2026 &&
            date.month == 9 &&
            (date.day == 26 || date.day == 27),
      );
    }
    if (has26 ||
        _containsWord(normalizedQuery, 'dissabte') ||
        _containsWord(normalizedQuery, 'avui')) {
      return _DateFilter(
        label: '26 set. 2026',
        matches: (date) =>
            date.year == 2026 && date.month == 9 && date.day == 26,
      );
    }
    if (has27 ||
        _containsWord(normalizedQuery, 'diumenge') ||
        _containsWord(normalizedQuery, 'dema')) {
      return _DateFilter(
        label: '27 set. 2026',
        matches: (date) =>
            date.year == 2026 && date.month == 9 && date.day == 27,
      );
    }
    if (_containsWord(normalizedQuery, 'setembre') ||
        normalizedQuery.contains('aquest mes')) {
      return _DateFilter(
        label: 'Setembre de 2026',
        matches: (date) => date.year == 2026 && date.month == 9,
      );
    }
    if (_containsWord(normalizedQuery, 'octubre')) {
      return _DateFilter(
        label: 'Octubre de 2026',
        matches: (date) => date.year == 2026 && date.month == 10,
      );
    }
    return null;
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (_containsWord(text, keyword)) return true;
    }
    return false;
  }

  static bool _containsWord(String normalizedText, String normalizedWord) {
    final pattern = RegExp(
      '(^|[^a-z0-9])${RegExp.escape(normalizedWord)}([^a-z0-9]|\$)',
    );
    return pattern.hasMatch(normalizedText);
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáäâ]'), 'a')
        .replaceAll(RegExp(r'[èéëê]'), 'e')
        .replaceAll(RegExp(r'[ìíïî]'), 'i')
        .replaceAll(RegExp(r'[òóöô]'), 'o')
        .replaceAll(RegExp(r'[ùúüû]'), 'u')
        .replaceAll('ç', 'c');
  }
}

class _DateFilter {
  const _DateFilter({required this.label, required this.matches});

  final String label;
  final bool Function(DateTime date) matches;
}
