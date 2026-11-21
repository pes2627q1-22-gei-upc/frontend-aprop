import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../../../activities/presentation/formatters/activity_categories_formatter.dart';
import '../../../activities/presentation/formatters/activity_date_formatter.dart';
import '../../../activities/presentation/widgets/activity_image.dart';
import '../../../activities/presentation/widgets/enrollment_badge.dart';
import '../../../../core/l10n/locale_controller.dart';

/// Compact plan of the selected day. The image and the title open the event.
class AgendaPlanCard extends StatelessWidget {
  const AgendaPlanCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.participationAction,
    this.rating,
    this.dayPosition,
  });

  final Activity activity;
  final VoidCallback onTap;

  /// The shared enrollment action («Apuntat» and «Desapunta’m»), as in the
  /// activity cards. Without it, only the «Apuntat» badge is shown.
  final Widget? participationAction;

  /// Rating block, shown only for plans the app lets the user rate.
  final Widget? rating;

  /// «Dia X de N» of a short multi-day plan on the day shown.
  final ({int day, int of})? dayPosition;

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
      // Tocar qualsevol lloc obre l'activitat; els botons de dins fan la
      // seva acció. Per al lector de pantalla, la imatge i el títol ja són
      // els botons per obrir-la.
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onTap,
                  child: ActivityImage(
                    activity: activity,
                    width: 72,
                    height: 72,
                    semanticLabel: context.l10n.assistantViewActivity(
                      activity.title,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        ?activityTimeLabel(activity, short: true),
                        activityCategoriesLabel(activity),
                      ].join(' · '),
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
                    if (dayPosition case final position?)
                      Text(
                        context.l10n.agendaDayOfTotal(
                          position.day,
                          position.of,
                        ),
                        style: secondaryStyle?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
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
                    ?rating,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _sourceLabel(Activity activity) {
    final creator = activity.creator;
    if (activity.source == ActivitySource.community && creator != null) {
      return currentL10n.agendaPublishedBy(creator.name);
    }
    return currentL10n.agendaSourceOfficial;
  }
}
