import 'package:aprop/features/activities/models/activity_filters.dart';
import 'package:aprop/features/activities/presentation/formatters/activity_filter_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'activity_filter_test_data.dart';

void main() {
  test('Date bounds include both whole days, regardless of their time', () {
    final range = ActivityDateRange(
      start: DateTime(2026, 9, 26, 19),
      end: DateTime(2026, 9, 27, 10),
    );
    expect(range.contains(DateTime(2026, 9, 25, 23, 59)), isFalse);
    expect(range.contains(DateTime(2026, 9, 26)), isTrue);
    expect(range.contains(DateTime(2026, 9, 27, 23, 59, 59)), isTrue);
    expect(range.contains(DateTime(2026, 9, 28)), isFalse);
    expect(
      () =>
          ActivityDateRange(start: DateTime(2026, 10), end: DateTime(2026, 9)),
      throwsArgumentError,
    );
  });

  test('Category alternatives are OR and combine with dates using AND', () {
    final source = [
      event('music', DateTime(2026, 9, 26)),
      event('theatre', DateTime(2026, 9, 27), category: 'Teatre'),
      event('exhibition', DateTime(2026, 9, 27), category: 'Exposicions'),
      event('later', DateTime(2026, 9, 28)),
    ];
    final filters = ActivityFilters(
      dates: ActivityDateRange(
        start: DateTime(2026, 9, 26),
        end: DateTime(2026, 9, 27),
      ),
      categories: ['Música', 'Teatre'],
    );
    expect(filters.applyTo(source).map((a) => a.id), ['music', 'theatre']);
    expect(ActivityFilters().applyTo(source), source);
    expect(filters.withCategories([]).applyTo(source), source.take(3));
    expect(filters.withDates(null).applyTo(source).length, 3);
  });

  test(
    'Categories tolerate accents and whitespace without inventing aliases',
    () {
      final filters = ActivityFilters(categories: ['Música']);
      expect(
        filters.matches(event('a', DateTime(2026), category: '  MUSICA  ')),
        isTrue,
      );
      expect(
        filters.matches(event('b', DateTime(2026), category: 'Mu\u0301sica')),
        isTrue,
      );
      expect(
        filters.matches(event('c', DateTime(2026), category: 'Activitat')),
        isFalse,
      );
      expect(
        filters.matches(event('d', DateTime(2026), category: 'Arts visuals')),
        isFalse,
      );
    },
  );

  test(
    'Filters are immutable value objects and copies preserve the other field',
    () {
      final selected = <String>{'Música', 'Teatre'};
      final dates = ActivityDateRange(start: DateTime(2026, 9, 26));
      final filters = ActivityFilters(dates: dates, categories: selected);
      selected.clear();
      expect(filters.categories, {'Música', 'Teatre'});
      expect(() => filters.categories.add('Cinema'), throwsUnsupportedError);
      final same = ActivityFilters(
        dates: dates,
        categories: ['Teatre', 'Música'],
      );
      expect(filters, same);
      expect(filters.hashCode, same.hashCode);
      expect(filters.withDates(null).categories, filters.categories);
      expect(filters.withCategories([]).dates, dates);
      expect(ActivityFilters().isActive, isFalse);
      expect(filters.isActive, isTrue);
    },
  );

  test(
    'Missing-category feedback counts only events inside the chosen dates',
    () {
      final filters = ActivityFilters(
        dates: ActivityDateRange(start: DateTime(2026, 9, 26)),
        categories: ['Teatre'],
      );
      final source = [
        event('unknown', DateTime(2026, 9, 26), category: 'Activitat'),
        event('missing', DateTime(2026, 9, 26), category: ''),
        event('outside', DateTime(2026, 9, 27), category: 'Activitat'),
        event('known', DateTime(2026, 9, 26)),
      ];
      expect(filters.missingCategoryCount(source), 2);
      expect(filters.withCategories([]).missingCategoryCount(source), 0);
    },
  );

  test('Presets use civil dates across month/year boundaries and weekends', () {
    final tomorrow = activityDatePresetRange(
      ActivityDatePreset.tomorrow,
      DateTime(2026, 12, 31, 23),
    );
    expect(tomorrow.start, DateTime(2027, 1, 1));
    final friday = activityDatePresetRange(
      ActivityDatePreset.thisWeekend,
      DateTime(2026, 9, 25),
    );
    final saturday = activityDatePresetRange(
      ActivityDatePreset.thisWeekend,
      DateTime(2026, 9, 26),
    );
    final sunday = activityDatePresetRange(
      ActivityDatePreset.thisWeekend,
      DateTime(2026, 9, 27),
    );
    expect(friday.start, DateTime(2026, 9, 26));
    expect(friday.end, DateTime(2026, 9, 27));
    expect(saturday, friday);
    expect(sunday, friday);
    expect(
      activityDatePresetRange(
        ActivityDatePreset.today,
        DateTime(2026, 10, 25, 17),
      ).start,
      DateTime(2026, 10, 25),
    );
  });

  test(
    'Summaries distinguish no restriction, a day and cross-year intervals',
    () {
      expect(formatFilterMonth(DateTime(2026, 9)), 'Setembre 2026');
      expect(formatFilterDateRange(null, year: 2026), 'Totes les dates');
      expect(
        formatFilterDateRange(
          ActivityDateRange(
            start: DateTime(2026, 9, 26),
            end: DateTime(2026, 9, 27),
          ),
          year: 2026,
        ),
        'Del 26 al 27 de setembre',
      );
      expect(
        formatFilterDateRange(
          ActivityDateRange(
            start: DateTime(2026, 12, 31),
            end: DateTime(2027, 1, 2),
          ),
          year: 2026,
        ),
        'Del 31 de desembre de 2026 al 2 de gener de 2027',
      );
      expect(
        formatFilterDateRange(
          ActivityDateRange(start: DateTime(2025, 4, 1)),
          year: 2026,
        ),
        '1 d’abril de 2025',
      );
    },
  );
}
