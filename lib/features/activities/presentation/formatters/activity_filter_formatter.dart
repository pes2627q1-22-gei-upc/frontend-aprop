import '../../../../core/l10n/date_labels.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity_category_labels.dart';
import '../../models/activity_filters.dart';

String formatFilterMonth(DateTime month) =>
    currentL10n.monthYear(capitalize(monthName(month.month)), month.year);

String formatFilterDateRange(ActivityDateRange? range, {required int year}) {
  final l10n = currentL10n;
  if (range == null) return l10n.rangeAll;
  final start = range.start;
  final end = range.end;
  String date(DateTime day, {bool includeYear = false}) =>
      includeYear ? dateWithYear(day) : dateWithoutYear(day);

  if (range.isSingleDay) return date(start, includeYear: start.year != year);
  if (start.year != end.year) {
    return l10n.rangeFromTo(
      date(start, includeYear: true),
      date(end, includeYear: true),
    );
  }
  if (start.month == end.month) {
    return l10n.rangeFromDayTo(
      start.day,
      date(start),
      date(end, includeYear: end.year != year),
    );
  }
  return l10n.rangeFromTo(
    date(start),
    date(end, includeYear: end.year != year),
  );
}

String formatCategorySelection(Set<String> categories) =>
    switch (categories.length) {
      0 => currentL10n.categoriesAll,
      1 => localizeActivityCategory(
        categories.single,
        languageCode: currentL10n.localeName,
      ),
      final count => currentL10n.categoriesSelected(count),
    };
