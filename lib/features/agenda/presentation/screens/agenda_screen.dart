import 'package:flutter/material.dart';

import '../../../activities/repositories/activity_repository.dart';
import '../../../activities/repositories/enrollment_repository.dart';
import '../formatters/agenda_date_formatter.dart';
import '../view_models/agenda_view_model.dart';
import '../widgets/agenda_plan_card.dart';
import '../widgets/month_calendar.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({
    super.key,
    required this.userId,
    required this.enrollmentRepository,
    required this.activityRepository,
    required this.onActivitySelected,
    this.now,
  });

  final String userId;
  final EnrollmentRepository enrollmentRepository;
  final ActivityRepository activityRepository;
  final ValueChanged<String> onActivitySelected;
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
  }

  @override
  void didUpdateWidget(AgendaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.enrollmentRepository != widget.enrollmentRepository ||
        oldWidget.activityRepository != widget.activityRepository) {
      _viewModel.dispose();
      _viewModel = _createViewModel();
    }
  }

  AgendaViewModel _createViewModel() {
    return AgendaViewModel(
      userId: widget.userId,
      enrollmentRepository: widget.enrollmentRepository,
      activityRepository: widget.activityRepository,
      now: widget.now,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final theme = Theme.of(context);
        final selectedDay = _viewModel.selectedDay;
        return ListView(
          key: const PageStorageKey<String>('agenda'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
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
            child: const Text('Tornar-ho a provar'),
          ),
        ),
      ];
    }

    if (_viewModel.isLoading || !_viewModel.hasLoaded) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Carregant la teva agenda',
            ),
          ),
        ),
      ];
    }

    final plans = _viewModel.selectedDayPlans;
    if (plans.isEmpty) {
      return [
        Text(
          'No tens cap pla per a aquest dia.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Apunta’t a activitats des d’Inici i les veuràs aquí.',
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
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}
