import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity_category_labels.dart';
import 'activity_filter_sheet.dart';

class ActivityCategoriesFilterSheet extends StatefulWidget {
  const ActivityCategoriesFilterSheet({
    super.key,
    required this.initialCategories,
    required this.categories,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });
  final Set<String> initialCategories;
  final List<String> categories;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<ActivityCategoriesFilterSheet> createState() =>
      _ActivityCategoriesFilterSheetState();
}

class _ActivityCategoriesFilterSheetState
    extends State<ActivityCategoriesFilterSheet> {
  late final Set<String> _selected = {...widget.initialCategories};

  bool _isSelected(String canonicalKey) => _selected.any(
    (item) => canonicalActivityCategoryKey(item) == canonicalKey,
  );

  void _toggle(String category, String canonicalKey, bool selected) {
    setState(() {
      _selected.removeWhere(
        (item) => canonicalActivityCategoryKey(item) == canonicalKey,
      );
      if (selected) _selected.add(category);
    });
  }

  List<({String raw, String key, String label})> _options(String languageCode) {
    final seen = <String>{};
    final items = <({String raw, String key, String label})>[];
    for (final category in widget.categories) {
      final key = canonicalActivityCategoryKey(category);
      if (key.isEmpty || !seen.add(key)) continue;
      final label = localizeActivityCategory(
        category,
        languageCode: languageCode,
      );
      if (label.isEmpty) continue;
      items.add((raw: category, key: key, label: label));
    }
    items.sort((a, b) => compareActivityCategoryLabels(a.label, b.label));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _options(context.l10n.localeName);
    return ActivityFilterSheet(
      title: context.l10n.actCategoriesTitle,
      subtitle: context.l10n.actCategoriesSubtitle,
      summary: Text(switch (_selected.length) {
        0 => context.l10n.categoriesAll,
        final count => context.l10n.categoriesSelected(count),
      }),
      onClear: () => setState(_selected.clear),
      onApply: widget.isLoading || widget.errorMessage != null
          ? null
          : () {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                Navigator.of(context).pop(Set<String>.unmodifiable(_selected));
              }
            },
      content: Column(
        children: [
          if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: context.l10n.actCategoriesLoading,
                ),
              ),
            )
          else if (widget.errorMessage case final error?)
            Column(
              children: [
                Semantics(liveRegion: true, child: Text(error)),
                TextButton(
                  onPressed: widget.onRetry,
                  child: Text(context.l10n.retry),
                ),
              ],
            )
          else if (options.isEmpty)
            Column(
              children: [
                Text(context.l10n.actCategoriesEmpty),
                if (widget.onRetry != null)
                  TextButton(
                    onPressed: widget.onRetry,
                    child: Text(context.l10n.retry),
                  ),
              ],
            ),
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: CheckboxListTile(
                  key: ValueKey('activity-filter-category-${option.label}'),
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
                    option.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: _isSelected(option.key),
                  selectedTileColor: theme.colorScheme.primary.withValues(
                    alpha: .06,
                  ),
                  activeColor: theme.colorScheme.primary,
                  checkColor: theme.colorScheme.onPrimary,
                  value: _isSelected(option.key),
                  onChanged: (selected) =>
                      _toggle(option.raw, option.key, selected == true),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
