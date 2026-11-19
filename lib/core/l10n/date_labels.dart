import 'locale_controller.dart';

/// Date and time wording in the active language (usable without a context).
String monthName(int month) => currentL10n.monthName('$month');

/// «de març», «d’abril» (Catalan), «October» (English).
String monthOf(int month) => currentL10n.monthOf('$month');

String weekdayName(int weekday) => currentL10n.weekdayName('$weekday');

String weekdayAbbreviation(int weekday) => currentL10n.weekdayAbbr('$weekday');

String capitalize(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

/// «20.00 h» in Catalan, without changing the time zone of [date].
String timeOfDay(DateTime date) => currentL10n.timeOfDay(
  date.hour.toString().padLeft(2, '0'),
  date.minute.toString().padLeft(2, '0'),
);

/// «Dissabte 24 d’octubre de 2026».
String longDate(DateTime date) => currentL10n.dateLong(
  weekdayName(date.weekday),
  date.day,
  monthOf(date.month),
  date.year,
);

/// «24 d’octubre de 2026».
String dateWithYear(DateTime date) =>
    currentL10n.dateWithYear(date.day, monthOf(date.month), date.year);

/// «24 d’octubre».
String dateWithoutYear(DateTime date) =>
    currentL10n.dateNoYear(date.day, monthOf(date.month));
