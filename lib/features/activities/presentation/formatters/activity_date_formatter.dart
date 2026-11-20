import '../../../../core/l10n/date_labels.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity.dart';

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

/// L'hora que es mostra d'una activitat. El backend només desa el dia de
/// l'inici (DP-029), així que mana el seu «Horari» («17.30 h», «A les 10 h»);
/// si no en té, l'hora de l'inici, llevat que sigui mitjanit (l'hora que
/// surt quan no se'n sap). Amb [short], només la primera línia i retallada.
String? activityTimeLabel(Activity activity, {bool short = false}) {
  final schedule = activity.schedule?.trim();
  if (schedule != null && schedule.isNotEmpty) {
    if (!short) return schedule;
    final line = schedule.split('\n').first.trim();
    return line.length <= _shortScheduleLength
        ? line
        : '${line.substring(0, _shortScheduleLength - 1).trimRight()}…';
  }
  final start = activity.startsAt;
  if (start.hour == 0 && start.minute == 0) return null;
  return formatActivityTime(start);
}

const _shortScheduleLength = 40;

/// «Dissabte · 17.30 h», o amb [includeDate] «Dissabte 24 d’octubre de 2026
/// · 17.30 h». Sense hora coneguda, només el dia.
String formatActivityWhen(Activity activity, {bool includeDate = false}) {
  final date = activity.startsAt;
  if (_isUnknownDate(date)) return currentL10n.dateUnknown;
  final day = includeDate
      ? formatActivityDate(date)
      : weekdayName(date.weekday);
  final time = activityTimeLabel(activity, short: !includeDate);
  return time == null ? day : currentL10n.scheduleJoin(day, time);
}

// TODO(DP-037): Go serializes an absent start date as its zero time, year 1.
// Keep that sentinel out of the UI until the API returns explicit nulls.
bool _isUnknownDate(DateTime date) =>
    date.year == 1 && date.month == 1 && date.day == 1;
