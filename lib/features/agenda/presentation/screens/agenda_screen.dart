import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../../../attendance/presentation/view_models/attendance_view_model.dart';
import '../../../attendance/presentation/widgets/how_did_it_go_card.dart';
import '../../../activities/repositories/activity_repository.dart';
import '../../../activities/repositories/enrollment_repository.dart';
import '../formatters/agenda_date_formatter.dart';
import '../view_models/agenda_view_model.dart';
import '../widgets/agenda_plan_card.dart';
import '../widgets/month_calendar.dart';
import '../../../../core/l10n/locale_controller.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({
    super.key,
    required this.userId,
    required this.enrollmentRepository,
    required this.activityRepository,
    required this.onActivitySelected,
    this.activitiesChanged,
    this.participationActionBuilder,
    this.ratingBuilder,
    this.attendanceViewModel,
    this.now,
  });

  final String userId;
  final EnrollmentRepository enrollmentRepository;
  final ActivityRepository activityRepository;
  final ValueChanged<String> onActivitySelected;

  /// Avisa que alguna activitat ha canviat (p. ex. se n'han desat canvis):
  /// l'Agenda torna a carregar els plans.
  final Listenable? activitiesChanged;

  /// Enrollment action for each plan, shared with the activity cards, so
  /// unenrolling works and looks the same everywhere.
  final Widget Function(Activity activity)? participationActionBuilder;

  /// Rating block for each plan; the app decides when it can be rated.
  final Widget Function(Activity activity)? ratingBuilder;

  /// Answers to «Com va anar?» (#64). Without it the question is not shown.
  final AttendanceViewModel? attendanceViewModel;
  final DateTime Function()? now;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late AgendaViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = _createViewModel();
    widget.activitiesChanged?.addListener(_reload);
  }

  void _reload() => _viewModel.refreshActivities();

  @override
  void didUpdateWidget(AgendaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activitiesChanged != widget.activitiesChanged) {
      oldWidget.activitiesChanged?.removeListener(_reload);
      widget.activitiesChanged?.addListener(_reload);
    }
    if (oldWidget.userId != widget.userId ||
        oldWidget.enrollmentRepository != widget.enrollmentRepository ||
        oldWidget.activityRepository != widget.activityRepository) {
      _viewModel.dispose();
      _viewModel = _createViewModel();
    }
  }

  AgendaViewModel _createViewModel() {
    final model = AgendaViewModel(
      userId: widget.userId,
      enrollmentRepository: widget.enrollmentRepository,
      activityRepository: widget.activityRepository,
      now: widget.now,
    );
    // Reads whether the started plans were attended («Com va anar?»).
    model.addListener(
      () => widget.attendanceViewModel?.ensureLoaded(
        model.startedPlans.map((plan) => plan.id),
      ),
    );
    return model..load();
  }

  @override
  void dispose() {
    widget.activitiesChanged?.removeListener(_reload);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendance = widget.attendanceViewModel;
    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, ?attendance]),
      builder: (context, child) {
        final theme = Theme.of(context);
        final selectedDay = _viewModel.selectedDay;
        final pending = attendance == null
            ? const <Activity>[]
            : [
                for (final plan in _viewModel.startedPlans)
                  if (attendance.isPending(plan.id) ||
                      attendance.isAnswering(plan.id) ||
                      attendance.errorFor(plan.id) != null)
                    plan,
              ];
        return ListView(
          key: const PageStorageKey<String>('agenda'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (pending.isNotEmpty && attendance != null) ...[
              HowDidItGoCard(activities: pending, viewModel: attendance),
              const SizedBox(height: 16),
            ],
            MonthCalendar(
              month: _viewModel.visibleMonth,
              selectedDay: selectedDay,
              today: _viewModel.today,
              hasPlansOn: _viewModel.hasPlansOn,
              onDaySelected: _viewModel.selectDay,
              onPreviousMonth: _viewModel.showPreviousMonth,
              onNextMonth: _viewModel.showNextMonth,
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                formatAgendaDay(selectedDay),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._buildDayContent(theme),
          ],
        );
      },
    );
  }

  List<Widget> _buildDayContent(ThemeData theme) {
    final errorMessage = _viewModel.errorMessage;
    if (errorMessage != null) {
      return [
        Text(errorMessage, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            onPressed: _viewModel.load,
            child: Text(context.l10n.retry),
          ),
        ),
      ];
    }

    if (_viewModel.isLoading || !_viewModel.hasLoaded) {
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

    final plans = _viewModel.selectedDayPlans;
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
      for (final activity in plans) ...[
        AgendaPlanCard(
          key: ValueKey(activity.id),
          activity: activity,
          onTap: () => widget.onActivitySelected(activity.id),
          participationAction: widget.participationActionBuilder?.call(
            activity,
          ),
          rating: widget.ratingBuilder?.call(activity),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}
