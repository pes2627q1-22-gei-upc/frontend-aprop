import '../../../../core/l10n/date_labels.dart';
import '../../../../core/l10n/locale_controller.dart';

/// Monday-first abbreviations used as calendar column headers.
List<String> get agendaWeekdayAbbreviations => [
  for (var day = 1; day <= 7; day++) weekdayAbbreviation(day),
];

/// «Setembre de 2026».
String formatAgendaMonth(DateTime month) =>
    currentL10n.monthHeader(capitalize(monthName(month.month)), month.year);

/// «Dissabte, 26 de setembre» or «Dilluns, 19 d’octubre».
String formatAgendaDay(DateTime day) => currentL10n.weekdayDay(
  weekdayName(day.weekday),
  day.day,
  monthOf(day.month),
);

/// Date header for grouped agenda lists and day sheets: includes the year when
/// [day] is in a different year from [today].
String formatAgendaDayHeader(DateTime day, {required DateTime today}) =>
    day.year == today.year ? formatAgendaDay(day) : longDate(day);

/// «19.00 h», without changing the time zone of the supplied date.
String formatAgendaTime(DateTime date) => timeOfDay(date);
