import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../formatters/activity_date_formatter.dart';

/// Panell inferior per triar la data i l'hora d'inici amb rodes: dia, mes i
/// any, i l'hora en intervals de 15 minuts. Retorna el moment triat, o `null`
/// si es cancel·la.
Future<DateTime?> showStartDateTimeSheet(
  BuildContext context, {
  required DateTime initial,
  required DateTime now,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _StartDateTimeSheet(initial: initial, now: now),
  );
}

const _minuteStep = 15;
const _itemExtent = 40.0;
const _wheelHeight = 160.0;

class _StartDateTimeSheet extends StatefulWidget {
  const _StartDateTimeSheet({required this.initial, required this.now});

  final DateTime initial;
  final DateTime now;

  @override
  State<_StartDateTimeSheet> createState() => _StartDateTimeSheetState();
}

class _StartDateTimeSheetState extends State<_StartDateTimeSheet> {
  late int _day = widget.initial.day;
  late int _month = widget.initial.month;
  late int _year = widget.initial.year;

  /// Minuts des de mitjanit, múltiple de [_minuteStep].
  late int _minutes =
      (widget.initial.hour * 60 + widget.initial.minute) ~/
      _minuteStep *
      _minuteStep;

  late final _dayController = FixedExtentScrollController(
    initialItem: _day - 1,
  );
  late final _monthController = FixedExtentScrollController(
    initialItem: _month - 1,
  );
  late final _yearController = FixedExtentScrollController(
    initialItem: _year - _firstYear,
  );
  late final _timeController = FixedExtentScrollController(
    initialItem: _minutes ~/ _minuteStep,
  );

  int get _firstYear => widget.now.year;
  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);

  DateTime get _selected =>
      DateTime(_year, _month, _day, _minutes ~/ 60, _minutes % 60);

  bool get _isValid => _selected.isAfter(widget.now);

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  /// En canviar de mes o d'any, el dia no pot passar de l'últim del mes (el
  /// 31 de gener passa a ser el 28 o 29 de febrer).
  void _updateMonth({int? month, int? year}) {
    setState(() {
      _month = month ?? _month;
      _year = year ?? _year;
      if (_day > _daysInMonth) {
        _day = _daysInMonth;
        _dayController.jumpToItem(_day - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = _selected;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Data i hora d’inici',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // Resum del que hi ha triat, com una targeta.
            Semantics(
              liveRegion: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      Text(
                        formatActivityDate(selected),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        formatActivityTime(selected),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: _wheelHeight,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _Wheel(
                      key: const ValueKey('start-day'),
                      label: 'Dia',
                      controller: _dayController,
                      itemCount: _daysInMonth,
                      itemLabel: (index) => '${index + 1}',
                      onChanged: (index) => setState(() => _day = index + 1),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: _Wheel(
                      key: const ValueKey('start-month'),
                      label: 'Mes',
                      controller: _monthController,
                      itemCount: 12,
                      itemLabel: (index) => catalanMonths[index],
                      onChanged: (index) => _updateMonth(month: index + 1),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _Wheel(
                      key: const ValueKey('start-year'),
                      label: 'Any',
                      controller: _yearController,
                      itemCount: 3,
                      itemLabel: (index) => '${_firstYear + index}',
                      onChanged: (index) =>
                          _updateMonth(year: _firstYear + index),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            SizedBox(
              height: _wheelHeight,
              child: _Wheel(
                key: const ValueKey('start-time'),
                label: 'Hora',
                controller: _timeController,
                itemCount: 24 * 60 ~/ _minuteStep,
                itemLabel: (index) {
                  final minutes = index * _minuteStep;
                  return formatActivityTime(
                    DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60),
                  );
                },
                onChanged: (index) =>
                    setState(() => _minutes = index * _minuteStep),
              ),
            ),
            const SizedBox(height: 8),
            if (!_isValid)
              Text(
                'L’inici ha de ser posterior a ara.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.error),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Cancel·la'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isValid
                        ? () => Navigator.of(context).pop(selected)
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Fet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    super.key,
    required this.label,
    required this.controller,
    required this.itemCount,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) itemLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;

    return Semantics(
      label: label,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: _itemExtent,
        onSelectedItemChanged: onChanged,
        children: [
          for (var index = 0; index < itemCount; index++)
            Center(child: Text(itemLabel(index), style: style)),
        ],
      ),
    );
  }
}
