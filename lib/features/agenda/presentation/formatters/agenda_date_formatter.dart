const _weekdays = [
  'Dilluns',
  'Dimarts',
  'Dimecres',
  'Dijous',
  'Divendres',
  'Dissabte',
  'Diumenge',
];

const _months = [
  'gener',
  'febrer',
  'març',
  'abril',
  'maig',
  'juny',
  'juliol',
  'agost',
  'setembre',
  'octubre',
  'novembre',
  'desembre',
];

/// Monday-first abbreviations used as calendar column headers.
const agendaWeekdayAbbreviations = ['Dl', 'Dt', 'Dc', 'Dj', 'Dv', 'Ds', 'Dg'];

String _monthName(int month) => _months[month - 1];

String _withPreposition(String month) =>
    'aeiou'.contains(month[0]) ? 'd’$month' : 'de $month';

/// «Setembre de 2026».
String formatAgendaMonth(DateTime month) {
  final name = _monthName(month.month);
  return '${name[0].toUpperCase()}${name.substring(1)} de ${month.year}';
}

/// «Dissabte, 26 de setembre» or «Dilluns, 19 d’octubre».
String formatAgendaDay(DateTime day) =>
    '${_weekdays[day.weekday - 1]}, ${day.day} '
    '${_withPreposition(_monthName(day.month))}';

/// «19.00 h», without changing the time zone of the supplied date.
String formatAgendaTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour.$minute h';
}
