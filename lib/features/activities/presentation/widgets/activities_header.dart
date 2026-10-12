import 'package:flutter/material.dart';

enum ActivitiesView { map, list }

/// Dibuixa els controls d'Inici; la pantalla decideix què fa cada acció.
class ActivitiesHeader extends StatelessWidget {
  const ActivitiesHeader({
    super.key,
    required this.selectedView,
    this.onAssistantPressed,
    this.onLocationPressed,
    this.onDatesPressed,
    this.onCategoriesPressed,
    this.onMapPressed,
    this.onListPressed,
  });

  final ActivitiesView selectedView;
  final VoidCallback? onAssistantPressed;
  final VoidCallback? onLocationPressed;
  final VoidCallback? onDatesPressed;
  final VoidCallback? onCategoriesPressed;
  final VoidCallback? onMapPressed;
  final VoidCallback? onListPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Image.asset(
                  'assets/branding/aprop_logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  semanticLabel: 'AProp!',
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: onAssistantPressed == null
                    ? 'Assistent disponible properament'
                    : 'Obrir l’assistent',
                child: FilledButton.tonalIcon(
                  onPressed: onAssistantPressed,
                  icon: const Icon(Icons.smart_toy_outlined, size: 20),
                  label: const Text('Assistent'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    disabledBackgroundColor: colors.primaryContainer,
                    disabledForegroundColor: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final filters = [
                _FilterButton(
                  label: 'Catalunya',
                  icon: Icons.location_on_outlined,
                  onPressed: onLocationPressed,
                ),
                _FilterButton(
                  label: 'Dates',
                  icon: Icons.calendar_month_outlined,
                  onPressed: onDatesPressed,
                ),
                _FilterButton(
                  label: 'Categories',
                  icon: Icons.sell_outlined,
                  onPressed: onCategoriesPressed,
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
                      label: 'Mapa',
                      icon: Icons.map_outlined,
                      selected: selectedView == ActivitiesView.map,
                      onPressed: onMapPressed,
                    ),
                  ),
                  Expanded(
                    child: _ViewButton(
                      label: 'Llista',
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: onPressed == null ? '$label disponible properament' : label,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          backgroundColor: colors.surface,
          disabledForegroundColor: colors.onSurfaceVariant,
          side: BorderSide(color: colors.outlineVariant),
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
            const Icon(Icons.expand_more, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
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
            ? 'Vista $label seleccionada'
            : onPressed == null
            ? 'Vista $label disponible properament'
            : 'Mostrar $label',
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
