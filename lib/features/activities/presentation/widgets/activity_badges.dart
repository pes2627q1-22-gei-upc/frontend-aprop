import 'package:flutter/material.dart';

class ActivityCategoryBadge extends StatelessWidget {
  const ActivityCategoryBadge({super.key, required this.category});

  final String category;

  static const _backgrounds = {
    'Música': Color(0xFFFFE8E2),
    'Exposicions': Color(0xFFE3F2E5),
    'Teatre': Color(0xFFECE8FF),
  };

  static const _foregrounds = {
    'Música': Color(0xFFA83220),
    'Exposicions': Color(0xFF225B36),
    'Teatre': Color(0xFF4934A3),
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _ActivityBadge(
      label: category,
      background: _backgrounds[category] ?? colors.primaryContainer,
      foreground: _foregrounds[category] ?? colors.onPrimaryContainer,
    );
  }
}

class FriendshipBadge extends StatelessWidget {
  const FriendshipBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ActivityBadge(
      label: 'Amiga',
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
