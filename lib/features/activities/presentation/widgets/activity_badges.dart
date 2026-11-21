import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity_category_labels.dart';

/// Maximum number of category chips shown on the activity detail screen before
/// collapsing the rest into a `+N` badge.
// TODO(DP-083): Detail chip cap without a dedicated mockup.
const maxDetailActivityCategories = 3;

class ActivityCategoryBadge extends StatelessWidget {
  const ActivityCategoryBadge({super.key, required this.category});

  final String category;

  static const _backgrounds = {
    'musica': Color(0xFFFFE8E2),
    'exposicions': Color(0xFFE3F2E5),
    'teatre': Color(0xFFECE8FF),
  };

  static const _foregrounds = {
    'musica': Color(0xFFA83220),
    'exposicions': Color(0xFF225B36),
    'teatre': Color(0xFF4934A3),
  };

  /// Colors de la categoria, perquè altres controls (com el selector del
  /// formulari de creació) facin servir els mateixos que la insígnia.
  static ({Color background, Color foreground}) colorsFor(
    String category,
    ColorScheme colors,
  ) {
    final key = canonicalActivityCategoryKey(category);
    return (
      background: _backgrounds[key] ?? colors.primaryContainer,
      foreground: _foregrounds[key] ?? colors.onPrimaryContainer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryColors = colorsFor(category, Theme.of(context).colorScheme);
    final label = localizeActivityCategory(
      category,
      languageCode: context.l10n.localeName,
    );

    return _ActivityBadge(
      label: label,
      background: categoryColors.background,
      foreground: categoryColors.foreground,
    );
  }
}

/// Compact `+N` badge for extra categories beyond the visible ones.
class ActivityCategoryOverflowBadge extends StatelessWidget {
  const ActivityCategoryOverflowBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n.actMoreCategories(count),
      excludeSemantics: true,
      child: _ActivityBadge(
        label: '+$count',
        background: colors.surfaceContainerHighest,
        foreground: colors.onSurfaceVariant,
      ),
    );
  }
}

/// La primera categoria (prioritzant-ne una que coincideixi amb el filtre
/// actiu, si n'hi ha) i, si n'hi ha més, quantes en falten («+2»).
class ActivityCategoriesSummary extends StatelessWidget {
  const ActivityCategoriesSummary({
    super.key,
    required this.categories,
    this.preferredCategories = const [],
  });

  final List<String> categories;
  final Iterable<String> preferredCategories;

  @override
  Widget build(BuildContext context) {
    final ordered = orderActivityCategoriesForFilter(
      categories,
      preferredCategories,
    );
    if (ordered.isEmpty) return const SizedBox.shrink();
    final more = ordered.length - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: ActivityCategoryBadge(category: ordered.first)),
        if (more > 0) ...[
          const SizedBox(width: 4),
          ActivityCategoryOverflowBadge(count: more),
        ],
      ],
    );
  }
}

class FriendshipBadge extends StatelessWidget {
  const FriendshipBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return _ActivityBadge(
      label: context.l10n.actFriendBadge,
      background: Color(0xFFFFF1CC),
      foreground: Color(0xFF785400),
      icon: Icons.people_outline,
    );
  }
}

class _ActivityBadge extends StatelessWidget {
  const _ActivityBadge({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: icon == null
            ? text
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: 6),
                  text,
                ],
              ),
      ),
    );
  }
}
//Empaqueta diseños para que sean llamdos desde activity_card.dart y se pueda mostrar el badge de amistad o el badge de categoria de actividad.
