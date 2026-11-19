import '../../../../core/l10n/date_labels.dart';
import '../../../../core/l10n/locale_controller.dart';

/// «20.00 h».
String formatActivityTime(DateTime date) => timeOfDay(date);

/// «Dissabte 24 d’octubre de 2026».
String formatActivityDate(DateTime date) {
  if (_isUnknownDate(date)) return currentL10n.dateUnknown;
  return longDate(date);
}

/// Formats an activity date for the active language without changing its time
/// zone.
String formatActivitySchedule(DateTime date, {bool includeDate = false}) {
  if (_isUnknownDate(date)) return currentL10n.dateUnknown;
  final day = includeDate
      ? formatActivityDate(date)
      : weekdayName(date.weekday);
  return currentL10n.scheduleJoin(day, formatActivityTime(date));
}

// TODO(DP-037): Go serializes an absent start date as its zero time, year 1.
// Keep that sentinel out of the UI until the API returns explicit nulls.
bool _isUnknownDate(DateTime date) =>
    date.year == 1 && date.month == 1 && date.day == 1;
