import 'package:flutter/material.dart';

import '../../models/activity.dart';
import 'activity_badges.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final creator = activity.creator;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (creator != null) ...[
              Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      creator.avatarAsset,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(Icons.person_outline),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Publicat per ${creator.name}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (creator.isFriend) ...[
                    const SizedBox(width: 8),
                    const FriendshipBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 112,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        activity.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return ColoredBox(
                            color: colors.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.image_outlined, size: 32),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ActivityCategoryBadge(category: activity.category),
                      const SizedBox(height: 6),
                      Text(
                        activity.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _InformationRow(
                        icon: Icons.location_on_outlined,
                        text: activity.municipality,
                      ),
                      const SizedBox(height: 6),
                      _InformationRow(
                        icon: Icons.calendar_today_outlined,
                        text: _formatDate(activity.startsAt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (activity.source == ActivitySource.culturalAgenda) ...[
              const SizedBox(height: 12),
              Text(
                'Font: Agenda Cultural · Generalitat',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Dilluns',
      'Dimarts',
      'Dimecres',
      'Dijous',
      'Divendres',
      'Dissabte',
      'Diumenge',
    ];

    final weekday = weekdays[date.weekday - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$weekday · $hour.$minute h';
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
      ],
    );
  }
}
//recibe un objeto Activity y construye su representación visual, la dibuja
//La mayor parte del código especifica cómo se colocan esos elementos, no operaciones de negocio.
