import 'package:flutter/material.dart';

import '../../models/activity_filters.dart';
import '../formatters/activity_filter_formatter.dart';
import 'activity_filter_calendar.dart';
import 'activity_filter_sheet.dart';

typedef ActivityDateSelection = ({ActivityDateRange? dates});

class ActivityDateFilterSheet extends StatefulWidget {
  const ActivityDateFilterSheet({
    super.key,
    required this.today,
    this.initialDates,
  });
  final DateTime today;
  final ActivityDateRange? initialDates;

  @override
  State<ActivityDateFilterSheet> createState() =>
      _ActivityDateFilterSheetState();
}

class _ActivityDateFilterSheetState extends State<ActivityDateFilterSheet> {
  late ActivityDateRange? _draft = widget.initialDates;
  late DateTime _month = DateTime(
    (_draft?.start ?? widget.today).year,
    (_draft?.start ?? widget.today).month,
  );
  bool _selectingEnd = false;

  void _selectDate(DateTime day) {
    setState(() {
      if (!_selectingEnd || _draft == null) {
        _draft = ActivityDateRange(start: day);
        _selectingEnd = true;
      } else {
        final anchor = _draft!.start;
        _draft = ActivityDateRange(
          start: day.isBefore(anchor) ? day : anchor,
          end: day.isBefore(anchor) ? anchor : day,
        );
        _selectingEnd = false;
      }
    });
  }

  void _selectPreset(ActivityDatePreset preset) {
    setState(() {
      _draft = activityDatePresetRange(preset, widget.today);
      _month = DateTime(_draft!.start.year, _draft!.start.month);
      _selectingEnd = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ActivityFilterSheet(
      title: 'Dates',
      subtitle: 'Tria un dia o un interval',
      onClear: () => setState(() {
        _draft = null;
        _selectingEnd = false;
      }),
      onApply: () {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          Navigator.of(context).pop<ActivityDateSelection>((dates: _draft));
        }
      },
      summary: Row(
        children: [
          const Icon(Icons.calendar_month_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(formatFilterDateRange(_draft, year: widget.today.year)),
          ),
        ],
      ),
      content: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final preset in ActivityDatePreset.values)
                  ChoiceChip(
                    label: Text(switch (preset) {
                      ActivityDatePreset.today => 'Avui',
                      ActivityDatePreset.tomorrow => 'Demà',
                      ActivityDatePreset.thisWeekend => 'Aquest cap de setmana',
                    }),
                    selected:
                        _draft == activityDatePresetRange(preset, widget.today),
                    selectedColor: colors.primary,
                    checkmarkColor: colors.onPrimary,
                    labelStyle: TextStyle(
                      color:
                          _draft ==
                              activityDatePresetRange(preset, widget.today)
                          ? colors.onPrimary
                          : colors.onSurface,
                    ),
                    onSelected: (_) => _selectPreset(preset),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ActivityFilterCalendar(
            month: _month,
            today: widget.today,
            selectedRange: _draft,
            onMonthChanged: (month) => setState(() => _month = month),
            onDateSelected: _selectDate,
          ),
        ],
      ),
    );
  }
}
