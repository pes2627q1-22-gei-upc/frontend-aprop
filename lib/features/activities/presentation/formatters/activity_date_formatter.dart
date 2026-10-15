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
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final day = includeDate
      ? '$weekday ${date.day} de ${months[date.month - 1]} de ${date.year}'
      : weekday;
  return '$day · $hour.$minute h';
}
