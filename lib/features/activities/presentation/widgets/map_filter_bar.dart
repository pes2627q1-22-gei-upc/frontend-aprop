import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';

/// Barra que sura a dalt del mapa, com a Google Maps (#274): el camp de cerca
/// i una sola fila de xips de filtres que es pot desplaçar. Ocupa el mínim:
/// la resta de la pantalla és mapa.
class MapFilterBar extends StatelessWidget {
  const MapFilterBar({
    super.key,
    this.onSearchPressed,
    this.onDatesPressed,
    this.onCategoriesPressed,
    this.onClearFilters,
    this.datesLabel,
    this.categoriesLabel,
  });

  /// Obre la cerca. Si és nul, no es mostra el camp.
  final VoidCallback? onSearchPressed;
  final VoidCallback? onDatesPressed;
  final VoidCallback? onCategoriesPressed;

  /// Si hi ha filtres, el xip per treure'ls tots.
  final VoidCallback? onClearFilters;

  /// Les dates o les categories triades («Avui», «Música»). Nul si el filtre
  /// no s'aplica: el xip mostra el nom del filtre.
  final String? datesLabel;
  final String? categoriesLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onSearchPressed case final onSearch?) ...[
          _SearchField(onPressed: onSearch),
          const SizedBox(height: 8),
        ],
        SingleChildScrollView(
          key: const ValueKey('map-filter-chips'),
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _FilterChip(
                key: const ValueKey('activities-filter-dates'),
                label: datesLabel ?? l10n.actFilterDates,
                tooltip: l10n.actFilterDates,
                icon: Icons.calendar_month_outlined,
                selected: datesLabel != null,
                onPressed: onDatesPressed,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                key: const ValueKey('activities-filter-categories'),
                label: categoriesLabel ?? l10n.actFilterCategories,
                tooltip: l10n.actFilterCategories,
                icon: Icons.sell_outlined,
                selected: categoriesLabel != null,
                onPressed: onCategoriesPressed,
              ),
              if (onClearFilters case final onClear?) ...[
                const SizedBox(width: 8),
                // Només la icona, perquè la fila no s'allargui.
                _FilterChip(
                  key: const ValueKey('activities-filter-clear'),
                  tooltip: l10n.actClearAllFilters,
                  icon: Icons.filter_alt_off_outlined,
                  onPressed: onClear,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      key: const ValueKey('map-search'),
      color: colors.surface,
      elevation: 3,
      shadowColor: colors.shadow.withValues(alpha: _shadowAlpha),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.search, color: colors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.discoverSearchField,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
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

/// Opacitat de l'ombra dels elements que suren sobre el mapa.
const _shadowAlpha = .3;

/// Xip arrodonit amb ombra perquè es vegi sobre el mapa.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    this.label,
    required this.tooltip,
    required this.icon,
    this.onPressed,
    this.selected = false,
  });

  /// Nul: només la icona (el nom és al consell i al lector de pantalla).
  final String? label;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimary : colors.onSurface;
    return Semantics(
      selected: selected,
      button: true,
      child: Tooltip(
        message: onPressed == null
            ? context.l10n.comingSoonTitled(tooltip)
            : tooltip,
        child: Material(
          color: selected ? colors.primary : colors.surface,
          elevation: 2,
          shadowColor: colors.shadow.withValues(alpha: _shadowAlpha),
          shape: StadiumBorder(
            side: selected
                ? BorderSide.none
                : BorderSide(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              // 48 dp: superfície tàctil mínima (docs/activity-filters.md).
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: label == null ? 11 : 14,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: foreground),
                    if (label case final label?) ...[
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: foreground),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
