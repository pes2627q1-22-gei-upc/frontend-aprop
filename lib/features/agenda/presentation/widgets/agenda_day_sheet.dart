import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../../activities/models/activity.dart';
import '../../../attendance/presentation/view_models/attendance_view_model.dart';
import '../formatters/agenda_date_formatter.dart';
import '../view_models/agenda_view_model.dart';
import 'agenda_plan_card.dart';

/// Modal bottom sheet listing only the signed-up plans for [day].
///
/// Tapping a plan pops the sheet with that activity's ID so [AgendaScreen] can
/// open its details route cleanly.
// TODO(DP-079): cards inside the day sheet omit the inline «Desapunta’m» action
// so the «Desfer» SnackBar is never trapped behind the modal barrier.
class AgendaDaySheet extends StatelessWidget {
  const AgendaDaySheet({
    super.key,
    required this.day,
    required this.viewModel,
    this.attendanceViewModel,
    this.ratingBuilder,
  });

  final DateTime day;
  final AgendaViewModel viewModel;
  final AttendanceViewModel? attendanceViewModel;
  final Widget Function(Activity activity)? ratingBuilder;

  void _selectActivity(BuildContext context, String activityId) {
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      Navigator.of(context).pop(activityId);
    }
  }

  void _close(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final maxHeight =
        MediaQuery.sizeOf(context).height * (largeText ? 0.88 : 0.78);

    return SafeArea(
      key: const ValueKey('agenda-day-sheet'),
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListenableBuilder(
          listenable: Listenable.merge([viewModel, ?attendanceViewModel]),
          builder: (context, child) {
            final plans = viewModel.plansOn(day);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            formatAgendaDayHeader(day, today: viewModel.today),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.agendaCloseDaySheet,
                        onPressed: () => _close(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                Flexible(
                  child: SingleChildScrollView(
                    key: const ValueKey('agenda-day-sheet-scroll'),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildBody(context, theme, plans),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    ThemeData theme,
    List<Activity> plans,
  ) {
    final errorMessage = viewModel.errorMessage;
    if (errorMessage != null) {
      return [
        Text(errorMessage, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            onPressed: viewModel.load,
            child: Text(context.l10n.retry),
          ),
        ),
      ];
    }

    if (viewModel.isLoading || !viewModel.hasLoaded) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              semanticsLabel: context.l10n.agendaLoading,
            ),
          ),
        ),
      ];
    }

    if (plans.isEmpty) {
      return [
        Text(
          context.l10n.agendaEmptyDay,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.agendaEmptyHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ];
    }

    return [
      for (var i = 0; i < plans.length; i++) ...[
        AgendaPlanCard(
          key: ValueKey('agenda-day-sheet-plan-${plans[i].id}'),
          activity: plans[i],
          dayPosition: viewModel.dayPosition(plans[i], day),
          onTap: () => _selectActivity(context, plans[i].id),
          rating: ratingBuilder?.call(plans[i]),
        ),
        if (i + 1 < plans.length) const SizedBox(height: 12),
      ],
    ];
  }
}
