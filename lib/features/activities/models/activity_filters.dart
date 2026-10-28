import 'activity.dart';

/// Calendar days are kept as local civil dates, matching the catalogue.
class ActivityDateRange {
  ActivityDateRange({required DateTime start, DateTime? end})
    : start = _day(start),
      end = _day(end ?? start) {
    if (this.end.isBefore(this.start)) {
      throw ArgumentError('The end date must not precede the start date.');
    }
  }

  final DateTime start;
  final DateTime end;

  bool get isSingleDay => start == end;

  bool contains(DateTime value) {
    final day = _day(value);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      other is ActivityDateRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

enum ActivityDatePreset { today, tomorrow, thisWeekend }

ActivityDateRange activityDatePresetRange(
  ActivityDatePreset preset,
  DateTime today,
) {
  final day = _day(today);
  return switch (preset) {
    ActivityDatePreset.today => ActivityDateRange(start: day),
    ActivityDatePreset.tomorrow => ActivityDateRange(
      start: DateTime(day.year, day.month, day.day + 1),
    ),
    ActivityDatePreset.thisWeekend => ActivityDateRange(
      start: DateTime(
        day.year,
        day.month,
        day.day + (day.weekday == DateTime.sunday ? -1 : 6 - day.weekday),
      ),
      end: DateTime(
        day.year,
        day.month,
        day.day + (day.weekday == DateTime.sunday ? 0 : 7 - day.weekday),
      ),
    ),
  };
}

/// Approved example labels for the demo catalogue. HTTP uses GET /categories.
const activityFilterCategories = [
  'Música',
  'Teatre',
  'Cinema',
  'Dansa',
  'Exposicions',
  'Llibres i lletres',
  'Fires i mercats',
  'Cultura popular',
];

class ActivityFilters {
  ActivityFilters({this.dates, Iterable<String> categories = const []})
    : categories = Set.unmodifiable(categories),
      _categoryKeys = Set.unmodifiable(categories.map(_categoryKey));

  final ActivityDateRange? dates;
  final Set<String> categories;
  final Set<String> _categoryKeys;

  bool get isActive => dates != null || categories.isNotEmpty;

  ActivityFilters withDates(ActivityDateRange? value) =>
      ActivityFilters(dates: value, categories: categories);

  ActivityFilters withCategories(Iterable<String> value) =>
      ActivityFilters(dates: dates, categories: value);

  bool matches(Activity activity) =>
      (dates?.contains(activity.startsAt) ?? true) &&
      (_categoryKeys.isEmpty ||
          activity.categories.any(
            (category) => _categoryKeys.contains(_categoryKey(category)),
          ));

  List<Activity> applyTo(Iterable<Activity> source) =>
      List.unmodifiable(source.where(matches));

  /// Unknown categories are not silently treated as matching a chosen one.
  int missingCategoryCount(Iterable<Activity> source) => categories.isEmpty
      ? 0
      : source
            .where(
              (activity) =>
                  (dates?.contains(activity.startsAt) ?? true) &&
                  activity.categories.every(
                    (category) =>
                        {'', 'activitat'}.contains(_categoryKey(category)),
                  ),
            )
            .length;

  @override
  bool operator ==(Object other) =>
      other is ActivityFilters &&
      dates == other.dates &&
      categories.length == other.categories.length &&
      categories.every(other.categories.contains);

  @override
  int get hashCode => Object.hash(dates, Object.hashAllUnordered(categories));
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

String _categoryKey(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[àáâäãå]'), 'a')
    .replaceAll(RegExp('[èéêë]'), 'e')
    .replaceAll(RegExp('[ìíîï]'), 'i')
    .replaceAll(RegExp('[òóôöõ]'), 'o')
    .replaceAll(RegExp('[ùúûü]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp('[\u0300-\u036f]'), '')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');
