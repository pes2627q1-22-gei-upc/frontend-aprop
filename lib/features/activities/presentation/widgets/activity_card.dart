import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../formatters/activity_date_formatter.dart';
import 'activity_badges.dart';
import 'activity_information_row.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity, required this.onTap});

  final Activity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final creator = activity.creator;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                activity.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ActivityInformationRow(
                          icon: Icons.location_on_outlined,
                          text: activity.municipality,
                        ),
                        const SizedBox(height: 6),
                        ActivityInformationRow(
                          icon: Icons.calendar_today_outlined,
                          text: formatActivitySchedule(activity.startsAt),
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
      ),
    );
  }
}
//recibe un objeto Activity y construye su representación visual, la dibuja
//La mayor parte del código especifica cómo se colocan esos elementos, no operaciones de negocio.
