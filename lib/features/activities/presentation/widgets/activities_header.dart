import 'package:flutter/material.dart';

import '../../../../core/widgets/aprop_logo.dart';
import '../../../../core/l10n/locale_controller.dart';

enum ActivitiesView { map, list }

/// Dibuixa els controls d'Inici; la pantalla decideix què fa cada acció.
class ActivitiesHeader extends StatelessWidget {
  const ActivitiesHeader({
    super.key,
    required this.selectedView,
    this.onCreatePressed,
    this.onLocationPressed,
    this.onDatesPressed,
    this.onCategoriesPressed,
    this.onMapPressed,
    this.onListPressed,
    this.datesSelected = false,
    this.categoriesSelected = false,
    this.filterSummary,
    this.onClearFilters,
  });

  final ActivitiesView selectedView;
  final VoidCallback? onCreatePressed;
  final VoidCallback? onLocationPressed;
  final VoidCallback? onDatesPressed;
  final VoidCallback? onCategoriesPressed;
  final VoidCallback? onMapPressed;
  final VoidCallback? onListPressed;
  final bool datesSelected;
  final bool categoriesSelected;
  final String? filterSummary;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActivitiesBrand(onCreatePressed: onCreatePressed),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final filters = [
                _FilterButton(
                  label: context.l10n.actFilterLocation,
                  icon: Icons.location_on_outlined,
                  onPressed: onLocationPressed,
                ),
                _FilterButton(
                  key: const ValueKey('activities-filter-dates'),
                  label: context.l10n.actFilterDates,
                  icon: Icons.calendar_month_outlined,
                  onPressed: onDatesPressed,
                  selected: datesSelected,
                ),
                _FilterButton(
                  key: const ValueKey('activities-filter-categories'),
                  label: context.l10n.actFilterCategories,
                  icon: Icons.sell_outlined,
                  onPressed: onCategoriesPressed,
                  selected: categoriesSelected,
                ),
              ];

              // Amb text gran o una pantalla estreta, permetem més d'una fila.
              final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
              if (constraints.maxWidth < 330 || largeText) {
                return Wrap(spacing: 8, runSpacing: 8, children: filters);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 11, child: filters[0]),
                  const SizedBox(width: 8),
                  Expanded(flex: 9, child: filters[1]),
                  const SizedBox(width: 8),
                  Expanded(flex: 13, child: filters[2]),
                ],
              );
            },
          ),
          if (filterSummary case final summary?)
            Row(
              children: [
                Expanded(child: Text(summary)),
                IconButton(
                  onPressed: onClearFilters,
                  tooltip: context.l10n.actClearAllFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                ),
              ],
            ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _ViewButton(
                      key: const ValueKey('activities-view-map'),
                      label: context.l10n.actViewMap,
                      icon: Icons.map_outlined,
                      selected: selectedView == ActivitiesView.map,
                      onPressed: onMapPressed,
                    ),
                  ),
                  Expanded(
                    child: _ViewButton(
                      key: const ValueKey('activities-view-list'),
                      label: context.l10n.actViewList,
                      icon: Icons.format_list_bulleted,
                      selected: selectedView == ActivitiesView.list,
                      onPressed: onListPressed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitiesBrand extends StatelessWidget {
  const _ActivitiesBrand({required this.onCreatePressed});
  final VoidCallback? onCreatePressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Només el «+»: el nom surt al consell i el llegeix el lector de pantalla.
    final create = IconButton.filledTonal(
      onPressed: onCreatePressed,
      tooltip: onCreatePressed == null
          ? context.l10n.actCreateSoon
          : context.l10n.actCreate,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      style: IconButton.styleFrom(
        disabledBackgroundColor: colors.primaryContainer,
        disabledForegroundColor: colors.onSurfaceVariant,
      ),
      icon: const Icon(Icons.add),
    );
    return Row(
      children: [
        const Expanded(child: APropLogo(alignment: Alignment.centerLeft)),
        // Al mapa no es crea res: el «+» és a la capçalera d'Inici (#273).
        if (onCreatePressed != null) ...[const SizedBox(width: 8), create],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      selected: selected,
      child: Tooltip(
        message: onPressed == null
            ? context.l10n.comingSoonTitled(label)
            : label,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            backgroundColor: selected
                ? colors.primary.withValues(alpha: .08)
                : colors.surface,
            disabledForegroundColor: colors.onSurfaceVariant,
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 4),
              Flexible(child: Text(label)),
              const SizedBox(width: 4),
              Icon(selected ? Icons.check : Icons.expand_more, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimary : colors.primary;

    return Semantics(
      selected: selected,
      child: Tooltip(
        message: selected
            ? context.l10n.actViewSelected(label)
            : onPressed == null
            ? context.l10n.actViewSoon(label)
            : context.l10n.actViewShow(label),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            backgroundColor: selected ? colors.primary : Colors.transparent,
            foregroundColor: foreground,
            disabledForegroundColor: selected
                ? foreground
                : colors.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }
}
