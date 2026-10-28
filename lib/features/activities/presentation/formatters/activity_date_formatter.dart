const catalanWeekdays = [
  'Dilluns',
  'Dimarts',
  'Dimecres',
  'Dijous',
  'Divendres',
  'Dissabte',
  'Diumenge',
];

const catalanMonths = [
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

/// «20.00 h».
String formatActivityTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour.$minute h';
}

/// «Dissabte 24 d’octubre de 2026».
String formatActivityDate(DateTime date) {
  if (_isUnknownDate(date)) return 'Data no informada';
  final weekday = catalanWeekdays[date.weekday - 1];
  final month = catalanMonths[date.month - 1];
  // «d’abril», «d’agost», «d’octubre»: la preposició s'apostrofa davant de
  // vocal.
  final ofMonth = 'aeiou'.contains(month[0]) ? 'd’$month' : 'de $month';
  return '$weekday ${date.day} $ofMonth de ${date.year}';
}

/// Formats an activity date for the Catalan UI without changing its time zone.
String formatActivitySchedule(DateTime date, {bool includeDate = false}) {
  if (_isUnknownDate(date)) return 'Data no informada';
  final day = includeDate
      ? formatActivityDate(date)
      : catalanWeekdays[date.weekday - 1];
  return '$day · ${formatActivityTime(date)}';
}

// TODO(DP-037): Go serializes an absent start date as its zero time, year 1.
// Keep that sentinel out of the UI until the API returns explicit nulls.
bool _isUnknownDate(DateTime date) =>
    date.year == 1 && date.month == 1 && date.day == 1;
