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
  final weekday = catalanWeekdays[date.weekday - 1];
  final month = catalanMonths[date.month - 1];
  // «d’abril», «d’agost», «d’octubre»: la preposició s'apostrofa davant de
  // vocal.
  final ofMonth = 'aeiou'.contains(month[0]) ? 'd’$month' : 'de $month';
  return '$weekday ${date.day} $ofMonth de ${date.year}';
}

/// Formats an activity date for the Catalan UI without changing its time zone.
String formatActivitySchedule(DateTime date, {bool includeDate = false}) {
  final day = includeDate
      ? formatActivityDate(date)
      : catalanWeekdays[date.weekday - 1];
  return '$day · ${formatActivityTime(date)}';
}
