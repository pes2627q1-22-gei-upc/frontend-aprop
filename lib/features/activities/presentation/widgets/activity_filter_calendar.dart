import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/activity_filters.dart';
import '../formatters/activity_date_formatter.dart';
import '../formatters/activity_filter_formatter.dart';

class ActivityFilterCalendar extends StatelessWidget {
  const ActivityFilterCalendar({
    super.key,
    required this.month,
    required this.today,
    required this.selectedRange,
    required this.onMonthChanged,
    required this.onDateSelected,
  });
  final DateTime month;
  final DateTime today;
  final ActivityDateRange? selectedRange;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateTime(month.year, month.month);
    final offset = first.weekday - DateTime.monday;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final rows = (offset + days + 6) ~/ 7;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mes anterior',
              onPressed: () =>
                  onMonthChanged(DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                formatFilterMonth(month),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Mes següent',
              onPressed: () =>
                  onMonthChanged(DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = math.max(constraints.maxWidth, 7 * 48.0);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final label in const [
                          'Dl',
                          'Dt',
                          'Dc',
                          'Dj',
                          'Dv',
                          'Ds',
                          'Dg',
                        ])
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: Center(child: Text(label)),
                            ),
                          ),
                      ],
                    ),
                    for (var week = 0; week < rows; week++)
                      Row(
                        children: [
                          for (var weekday = 0; weekday < 7; weekday++)
                            Expanded(
                              child: _cell(
                                context,
                                week * 7 + weekday - offset + 1,
                                days,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, int number, int days) {
    if (number < 1 || number > days) return const SizedBox(height: 48);
    final day = DateTime(month.year, month.month, number);
    final colors = Theme.of(context).colorScheme;
    final range = selectedRange;
    final selected = range?.contains(day) ?? false;
    final endpoint = range != null && (day == range.start || day == range.end);
    final isToday =
        day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    return Semantics(
      key: ValueKey('activity-filter-date-${day.year}-${day.month}-$number'),
      button: true,
      selected: selected,
      label: '${formatActivityDate(day)}${isToday ? ', avui' : ''}',
      onTap: () => onDateSelected(day),
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () => onDateSelected(day),
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (selected)
                  Positioned(
                    top: 6,
                    bottom: 6,
                    left: day == range!.start ? 24 : 0,
                    right: day == range.end ? 24 : 0,
                    child: ColoredBox(
                      color: colors.primary.withValues(alpha: .1),
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: endpoint ? colors.primary : null,
                    border: isToday && !endpoint
                        ? Border.all(color: colors.primary)
                        : null,
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: endpoint ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
