import 'package:flutter/material.dart';

import '../formatters/agenda_date_formatter.dart';

/// Monday-first month grid. Days with plans show a dot, today is outlined and
/// the selected day is filled.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.today,
    required this.hasPlansOn,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime month;
  final DateTime selectedDay;
  final DateTime today;
  final bool Function(DateTime day) hasPlansOn;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month).weekday - 1;
    final cellCount = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    final rows = <Widget>[];
    for (var start = 0; start < cellCount; start += 7) {
      rows.add(
        Row(
          children: [
            for (var cell = start; cell < start + 7; cell++)
              Expanded(
                child: _buildCell(cell - leadingBlanks + 1, daysInMonth),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPreviousMonth,
              tooltip: 'Mes anterior',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                header: true,
                child: Text(
                  formatAgendaMonth(month),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onNextMonth,
              tooltip: 'Mes següent',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final label in agendaWeekdayAbbreviations)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...rows,
      ],
    );
  }

  Widget _buildCell(int dayNumber, int daysInMonth) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 48);
    }
    final day = DateTime(month.year, month.month, dayNumber);
    return _DayCell(
      key: ValueKey('agenda-day-${day.year}-${day.month}-${day.day}'),
      day: day,
      isSelected: day == selectedDay,
      isToday: day == today,
      hasPlans: hasPlansOn(day),
      onTap: () => onDaySelected(day),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasPlans,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool hasPlans;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = [
      formatAgendaDay(day),
      if (isToday) 'avui',
      hasPlans ? 'amb plans' : 'sense plans',
    ].join(', ');

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colors.primary : null,
                border: isToday && !isSelected
                    ? Border.all(color: colors.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${day.day}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? colors.onPrimary
                              : colors.onSurface,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  if (hasPlans)
                    Container(
                      key: const ValueKey('agenda-plan-dot'),
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? colors.onPrimary : colors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
