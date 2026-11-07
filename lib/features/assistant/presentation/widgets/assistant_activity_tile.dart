import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../../../activities/presentation/formatters/activity_date_formatter.dart';
import '../../../activities/presentation/widgets/activity_image.dart';

// TODO(DP-044): confirm the compact layout against mockup 10.
/// Compact activity row for assistant replies: a thumbnail, title,
/// place and date, and the shared participation action underneath. Several fit
/// on one screen, unlike the full `ActivityCard`.
class AssistantActivityTile extends StatelessWidget {
  const AssistantActivityTile({
    super.key,
    required this.activity,
    required this.onTap,
    this.participationAction,
  });

  final Activity activity;
  final VoidCallback onTap;
  final Widget? participationAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onTap,
                  child: ActivityImage(
                    activity: activity,
                    semanticLabel: 'Veure activitat: ${activity.title}',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '${activity.municipality} · '
                    '${formatActivitySchedule(activity.startsAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (participationAction != null) ...[
                    const SizedBox(height: 8),
                    participationAction!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
