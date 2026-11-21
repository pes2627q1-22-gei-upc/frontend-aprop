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

  /// Sends the answer and says so: the question disappears, and the stars
  /// may be on another day of the calendar.
  Future<void> _answer(BuildContext context, {required bool attended}) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final thanks = attended
        ? context.l10n.attendanceThanksYes(activity.title)
        : context.l10n.attendanceThanksNo;
    final saved = await viewModel.answer(activity.id, attended: attended);
    if (!saved) return;
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(thanks)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final busy = viewModel.isAnswering(activity.id);
    // «Sí» and «No» look the same (CA1): «No» is not a bad rating.
    final answerStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      backgroundColor: colors.secondaryContainer,
      foregroundColor: colors.onSecondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    final yes = FilledButton(
      key: ValueKey('attendance-yes-${activity.id}'),
      style: answerStyle,
      onPressed: busy ? null : () => _answer(context, attended: true),
      child: Text(context.l10n.attendanceYes, textAlign: TextAlign.center),
    );
    final no = FilledButton(
      key: ValueKey('attendance-no-${activity.id}'),
      style: answerStyle,
      onPressed: busy ? null : () => _answer(context, attended: false),
      child: Text(context.l10n.attendanceNo, textAlign: TextAlign.center),
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
            const SizedBox(height: 12),
            // Side by side and the same width; one under the other if they
            // do not fit (narrow screen or large text).
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(14) > 21;
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [yes, const SizedBox(height: 8), no],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: yes),
                    const SizedBox(width: 8),
                    Expanded(child: no),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                key: ValueKey('attendance-later-${activity.id}'),
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: busy ? null : () => viewModel.postpone(activity.id),
                child: Text(context.l10n.attendanceLater),
              ),
            ),
            if (busy)
              const LinearProgressIndicator()
            else if (viewModel.errorFor(activity.id) case final error?)
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
