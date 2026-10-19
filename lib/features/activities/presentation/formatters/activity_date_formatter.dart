/// Formats an activity date for the Catalan UI without changing its time zone.
String formatActivitySchedule(DateTime date, {bool includeDate = false}) {
  const weekdays = [
    'Dilluns',
    'Dimarts',
    'Dimecres',
    'Dijous',
    'Divendres',
    'Dissabte',
    'Diumenge',
  ];
  const months = [
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
  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  // «d’abril», «d’agost», «d’octubre»: la preposició s'apostrofa davant de
  // vocal.
  final ofMonth = 'aeiou'.contains(month[0]) ? 'd’$month' : 'de $month';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final day = includeDate
      ? '$weekday ${date.day} $ofMonth de ${date.year}'
      : weekday;
  return '$day · $hour.$minute h';
}
