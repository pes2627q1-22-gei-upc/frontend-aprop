import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../../activities/models/activity.dart';
import '../../../activities/repositories/activity_repository.dart';
import '../../../activities/repositories/enrollment_repository.dart';
import '../../../attendance/presentation/view_models/attendance_view_model.dart';
import '../../../attendance/presentation/widgets/how_did_it_go_card.dart';
import '../formatters/agenda_date_formatter.dart';
import '../view_models/agenda_view_model.dart';
import '../widgets/agenda_day_sheet.dart';
import '../widgets/agenda_plan_card.dart';
import '../widgets/month_calendar.dart';

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
  ModalBottomSheetRoute<String>? _activeDaySheetRoute;
  bool _showPastPlans = false;

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
      _closeDaySheet();
      _showPastPlans = false;
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

  void _closeDaySheet() {
    final route = _activeDaySheetRoute;
    _activeDaySheetRoute = null;
    if (route == null) return;
    // A root modal covers the bottom navigation. Remove only our own route
    // after the current frame if the screen/account disappears underneath it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route.isActive) route.navigator?.removeRoute(route);
    });
  }

  Future<void> _openDaySheet(DateTime day) async {
    _viewModel.selectDay(day);
    if (_activeDaySheetRoute != null) return;
    final owner = _viewModel;
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = ModalBottomSheetRoute<String>(
      settings: RouteSettings(
        name: '/agenda/day/${day.year}-${day.month}-${day.day}',
      ),
      builder: (_) => AgendaDaySheet(
        day: day,
        viewModel: owner,
        attendanceViewModel: widget.attendanceViewModel,
        ratingBuilder: widget.ratingBuilder,
      ),
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      barrierLabel: context.l10n.agendaCloseDaySheet,
    );
    _activeDaySheetRoute = route;
    final String? selectedActivityId;
    try {
      selectedActivityId = await navigator.push<String>(route);
    } finally {
      if (identical(_activeDaySheetRoute, route)) {
        _activeDaySheetRoute = null;
      }
    }
    if (!mounted || !identical(owner, _viewModel)) return;
    if (selectedActivityId != null) {
      widget.onActivitySelected(selectedActivityId);
    }
  }

  @override
  void dispose() {
    _closeDaySheet();
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
              onDaySelected: _openDaySheet,
              onPreviousMonth: _viewModel.showPreviousMonth,
              onNextMonth: _viewModel.showNextMonth,
            ),
            const SizedBox(height: 16),
            ..._buildPlansContent(theme),
          ],
        );
      },
    );
  }

  List<Widget> _buildPlansContent(ThemeData theme) {
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

    // TODO(DP-081): full upcoming list grouped by date + collapsible past
    // section below the calendar (deviates from fig. 11 inline day list).
    final upcomingGroups = _viewModel.upcomingPlanGroups;
    final pastGroups = _viewModel.pastPlanGroups;
    final pastCount = _viewModel.pastPlans.length;

    return [
      Semantics(
        header: true,
        child: Text(
          context.l10n.agendaUpcomingTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (upcomingGroups.isEmpty) ...[
        Text(
          pastGroups.isEmpty
              ? context.l10n.agendaEmptyAll
              : context.l10n.agendaEmptyUpcoming,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.agendaEmptyHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ] else
        ..._buildDayGroups(theme, upcomingGroups),
      if (pastGroups.isNotEmpty) ...[
        const SizedBox(height: 12),
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 8),
        _PastPlansToggle(
          count: pastCount,
          expanded: _showPastPlans,
          onToggle: () => setState(() => _showPastPlans = !_showPastPlans),
        ),
        if (_showPastPlans) ...[
          const SizedBox(height: 12),
          ..._buildDayGroups(theme, pastGroups),
        ],
      ],
    ];
  }

  List<Widget> _buildDayGroups(ThemeData theme, List<AgendaDayGroup> groups) {
    final today = _viewModel.today;
    final colors = theme.colorScheme;
    return [
      for (var i = 0; i < groups.length; i++) ...[
        Semantics(
          header: true,
          child: Text(
            formatAgendaDayHeader(groups[i].day, today: today),
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final activity in groups[i].plans) ...[
          AgendaPlanCard(
            key: _viewModel.dayPosition(activity, groups[i].day) == null
                ? ValueKey(activity.id)
                : ValueKey('${activity.id}-${groups[i].day}'),
            activity: activity,
            dayPosition: _viewModel.dayPosition(activity, groups[i].day),
            onTap: () => widget.onActivitySelected(activity.id),
            participationAction: widget.participationActionBuilder?.call(
              activity,
            ),
            rating: widget.ratingBuilder?.call(activity),
          ),
          const SizedBox(height: 12),
        ],
        if (i + 1 < groups.length) const SizedBox(height: 4),
      ],
    ];
  }
}

class _PastPlansToggle extends StatelessWidget {
  const _PastPlansToggle({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = context.l10n.agendaPastSection(count);
    return Semantics(
      button: true,
      expanded: expanded,
      label: label,
      onTap: onToggle,
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('agenda-past-toggle'),
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: colors.onSurface,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
