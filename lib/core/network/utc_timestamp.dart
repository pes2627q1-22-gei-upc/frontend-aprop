/// Strict RFC 3339 timestamp with microsecond precision. Zone-less SQL values
/// can be read as UTC only when their particular API contract permits it.
DateTime utcTimestamp(Object? value, {bool allowMissingZone = false}) {
  if (value is! String) throw const FormatException('Expected timestamp');
  final match = RegExp(
    r'^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.(\d{1,6}))?(Z|[+-]\d\d:\d\d)?$',
  ).firstMatch(value);
  if (match == null || (!allowMissingZone && match[8] == null)) {
    throw const FormatException('Expected exact timestamp with zone');
  }
  final year = int.parse(match[1]!),
      month = int.parse(match[2]!),
      day = int.parse(match[3]!);
  final hour = int.parse(match[4]!),
      minute = int.parse(match[5]!),
      second = int.parse(match[6]!);
  final civil = DateTime.utc(year, month, day, hour, minute, second);
  if (year < 2 ||
      civil.year != year ||
      civil.month != month ||
      civil.day != day ||
      hour > 23 ||
      minute > 59 ||
      second > 59) {
    throw const FormatException('Invalid timestamp');
  }
  final zone = match[8];
  if (zone != null &&
      zone != 'Z' &&
      (int.parse(zone.substring(1, 3)) > 23 ||
          int.parse(zone.substring(4, 6)) > 59)) {
    throw const FormatException('Invalid timestamp offset');
  }
  final parsed = DateTime.tryParse(match[8] == null ? '${value}Z' : value);
  if (parsed == null) throw const FormatException('Invalid timestamp');
  return parsed.toUtc();
}
