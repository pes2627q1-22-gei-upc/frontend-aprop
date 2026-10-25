import '../../models/activity_filters.dart';
import 'activity_date_formatter.dart';

String formatFilterMonth(DateTime month) {
  final name = catalanMonths[month.month - 1];
  return '${name[0].toUpperCase()}${name.substring(1)} ${month.year}';
}

String formatFilterDateRange(ActivityDateRange? range, {required int year}) {
  if (range == null) return 'Totes les dates';
  final start = range.start;
  final end = range.end;
  String date(DateTime day, {bool includeYear = false}) {
    final month = catalanMonths[day.month - 1];
    final ofMonth = 'aeiou'.contains(month[0]) ? 'd’$month' : 'de $month';
    return '${day.day} $ofMonth${includeYear ? ' de ${day.year}' : ''}';
  }

  if (range.isSingleDay) return date(start, includeYear: start.year != year);
  if (start.year != end.year) {
    return 'Del ${date(start, includeYear: true)} al ${date(end, includeYear: true)}';
  }
  if (start.month == end.month) {
    return 'Del ${start.day} al ${date(end, includeYear: end.year != year)}';
  }
  return 'Del ${date(start)} al ${date(end, includeYear: end.year != year)}';
}

String formatCategorySelection(Set<String> categories) =>
    switch (categories.length) {
      0 => 'Totes les categories',
      1 => categories.single,
      final count => '$count categories seleccionades',
    };
