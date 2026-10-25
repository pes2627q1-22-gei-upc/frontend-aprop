import 'package:flutter/material.dart';

import '../../models/activity_filters.dart';
import 'activity_filter_sheet.dart';

class ActivityCategoriesFilterSheet extends StatefulWidget {
  const ActivityCategoriesFilterSheet({
    super.key,
    required this.initialCategories,
  });
  final Set<String> initialCategories;

  @override
  State<ActivityCategoriesFilterSheet> createState() =>
      _ActivityCategoriesFilterSheetState();
}

class _ActivityCategoriesFilterSheetState
    extends State<ActivityCategoriesFilterSheet> {
  late final Set<String> _selected = {...widget.initialCategories};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActivityFilterSheet(
      title: 'Categories',
      subtitle: 'Pots triar més d’una categoria',
      summary: Text(switch (_selected.length) {
        0 => 'Totes les categories',
        1 => '1 categoria seleccionada',
        final count => '$count categories seleccionades',
      }),
      onClear: () => setState(_selected.clear),
      onApply: () {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          Navigator.of(context).pop(Set<String>.unmodifiable(_selected));
        }
      },
      content: Column(
        children: [
          for (final category in activityFilterCategories)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: CheckboxListTile(
                  key: ValueKey('activity-filter-category-$category'),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  title: Text(
                    category,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: _selected.contains(category),
                  selectedTileColor: theme.colorScheme.primary.withValues(
                    alpha: .06,
                  ),
                  activeColor: theme.colorScheme.primary,
                  checkColor: theme.colorScheme.onPrimary,
                  value: _selected.contains(category),
                  onChanged: (selected) => setState(() {
                    if (selected == true) {
                      _selected.add(category);
                    } else {
                      _selected.remove(category);
                    }
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
