import 'activity.dart';

/// When [activity] really starts. The backend keeps only the day of the start
/// (DP-029): midnight means «no hour», and the hour, if any, is in the
/// schedule («20 h», «A les 19.30 h», «19:00 – 21:00»). Null if the hour is
/// not known.
DateTime? activityStartTime(Activity activity) {
  final start = activity.startsAt;
  if (start.hour != 0 || start.minute != 0) return start;
  final time = scheduleStartHour(activity.schedule);
  if (time == null) return null;
  return DateTime(start.year, start.month, start.day, time.hour, time.minute);
}

/// Whether [activity] has already started at [now] (R8). Without a known
/// hour it only counts once its day is over: asking «Com va anar?» in the
/// morning of an evening concert would be wrong.
bool activityHasStarted(Activity activity, DateTime now) {
  final start = activityStartTime(activity);
  if (start != null) return !start.isAfter(now);
  final day = activity.startsAt;
  return !DateTime(day.year, day.month, day.day + 1).isAfter(now);
}

/// Clock used to hide finished activities; tests replace it.
DateTime Function() activityClock = DateTime.now;

/// Whether [activity] is over at [now]: its last day (the end day, or the
/// start day for one-day plans) has finished. Permanent activities never end.
/// The API still lists one-day events whose date passed when they have no end
/// date, so the app hides them (DP-080).
bool activityHasEnded(Activity activity, DateTime now) {
  if (activity.isPermanent) return false;
  final last = activity.endsAt ?? activity.startsAt;
  return !DateTime(last.year, last.month, last.day + 1).isAfter(now);
}

/// The first hour written in [schedule]: «20 h», «19.30 h», «19:30».
({int hour, int minute})? scheduleStartHour(String? schedule) {
  final text = schedule?.trim();
  if (text == null || text.isEmpty) return null;
  for (final match in _hourPattern.allMatches(text)) {
    final hour = int.parse(match.group(1) ?? match.group(3)!);
    final minute = int.parse(match.group(2) ?? match.group(4) ?? '0');
    if (hour < 24 && minute < 60) return (hour: hour, minute: minute);
  }
  return null;
}

/// «20 h» / «19.30 h» (with the «h»), or «19:30» / «19.30» (two digits for
/// the minutes). Not a number that belongs to a date or a price.
final _hourPattern = RegExp(
  r'(?<![\d.,/])(\d{1,2})(?:[.:](\d{2}))?\s*h(?![a-zàèéíòóú])'
  r'|(?<![\d.,/])(\d{1,2})[.:](\d{2})(?![\d.,/])',
  caseSensitive: false,
);
