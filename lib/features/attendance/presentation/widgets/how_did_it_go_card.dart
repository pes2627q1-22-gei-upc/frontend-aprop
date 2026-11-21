import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../../../activities/presentation/formatters/activity_date_formatter.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../view_models/attendance_view_model.dart';

/// «Com va anar?» (fig. 13): the plans that already started and still have
/// no answer, whatever day is selected in the Agenda.
class HowDidItGoCard extends StatelessWidget {
  const HowDidItGoCard({
    super.key,
    required this.activities,
    required this.viewModel,
  });

  final List<Activity> activities;
  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      key: const ValueKey('how-did-it-go'),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                context.l10n.attendanceQuestion,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.attendanceHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
            for (final activity in activities) ...[
              const SizedBox(height: 12),
              _Question(activity: activity, viewModel: viewModel),
            ],
          ],
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.activity, required this.viewModel});

  final Activity activity;
  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final busy = viewModel.isAnswering(activity.id);
    // «Sí» and «No» look the same: «No» is not a bad rating.
    final answerStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
    );
    return DecoratedBox(
      key: ValueKey('how-did-it-go-${activity.id}'),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(activity.title, style: theme.textTheme.titleSmall),
            Text(
              formatActivityDate(activity.startsAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  key: ValueKey('attendance-yes-${activity.id}'),
                  style: answerStyle,
                  onPressed: busy
                      ? null
                      : () => viewModel.answer(activity.id, attended: true),
                  child: Text(context.l10n.attendanceYes),
                ),
                FilledButton.tonal(
                  key: ValueKey('attendance-no-${activity.id}'),
                  style: answerStyle,
                  onPressed: busy
                      ? null
                      : () => viewModel.answer(activity.id, attended: false),
                  child: Text(context.l10n.attendanceNo),
                ),
                TextButton(
                  key: ValueKey('attendance-later-${activity.id}'),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                  onPressed: busy
                      ? null
                      : () => viewModel.postpone(activity.id),
                  child: Text(context.l10n.attendanceLater),
                ),
              ],
            ),
            if (viewModel.errorFor(activity.id) case final error?)
              Semantics(
                liveRegion: true,
                child: Text(error, style: TextStyle(color: colors.error)),
              ),
          ],
        ),
      ),
    );
  }
}
