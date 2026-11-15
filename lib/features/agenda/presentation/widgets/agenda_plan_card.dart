import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../../../activities/presentation/widgets/enrollment_badge.dart';
import '../formatters/agenda_date_formatter.dart';

/// Compact plan of the selected day. The image and the title open the event.
class AgendaPlanCard extends StatelessWidget {
  const AgendaPlanCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.participationAction,
  });

  final Activity activity;
  final VoidCallback onTap;

  /// The shared enrollment action («Apuntat» and «Desapunta’m»), as in the
  /// activity cards. Without it, only the «Apuntat» badge is shown.
  final Widget? participationAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTap,
                child: Image.asset(
                  activity.imageAsset,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  semanticLabel: 'Veure activitat: ${activity.title}',
                  errorBuilder: (context, error, stackTrace) {
                    return ColoredBox(
                      color: colors.surfaceContainerHighest,
                      child: const SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(Icons.image_outlined),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatAgendaTime(activity.startsAt)} · '
                    '${activity.category}',
                    style: secondaryStyle,
                  ),
                  InkWell(
                    onTap: onTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
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
                    ),
                  ),
                  if (activity.municipality.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.municipality,
                            style: secondaryStyle,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(_sourceLabel(activity), style: secondaryStyle),
                  const SizedBox(height: 8),
                  participationAction ?? const EnrolledBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _sourceLabel(Activity activity) {
    final creator = activity.creator;
    if (activity.source == ActivitySource.community && creator != null) {
      return 'Publicat per ${creator.name}';
    }
    return 'Font: Agenda Cultural · Generalitat';
  }
}
