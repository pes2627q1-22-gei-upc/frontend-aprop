import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../activities/models/activity.dart';
import '../../../activities/models/activity_start.dart';
import '../../../activities/repositories/activity_repository.dart';
import '../../../activities/repositories/enrollment_repository.dart';
import '../../../../core/l10n/locale_controller.dart';

/// Signed-up plans happening on a single calendar [day], ordered by start time.
class AgendaDayGroup {
  const AgendaDayGroup({required this.day, required this.plans});

  final DateTime day;
  final List<Activity> plans;
}

/// Month calendar and full list of the signed-in user's own plans
/// (confirmed enrollments).
class AgendaViewModel extends ChangeNotifier {
  AgendaViewModel({
    required this.userId,
    required this._enrollmentRepository,
    required this._activityRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _selectedDay = today;
    _visibleMonth = DateTime(_selectedDay.year, _selectedDay.month);
  }

  final String userId;
  final EnrollmentRepository _enrollmentRepository;
  final ActivityRepository _activityRepository;
  final DateTime Function() _now;

  StreamSubscription<Set<String>>? _subscription;
  final Map<String, Activity> _activityCache = {};

  /// Last enrolled IDs received, to read their activities again.
  Set<String> _enrolledIds = const {};
  Map<DateTime, List<Activity>> _plansByDay = const {};
  late DateTime _selectedDay;
  late DateTime _visibleMonth;
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isDisposed = false;
  int _subscriptionVersion = 0;
  int _resolveRequest = 0;
  String? _errorMessage;

  DateTime get today => _dateOnly(_now());
  DateTime get selectedDay => _selectedDay;

  /// First day of the month shown by the calendar.
  DateTime get visibleMonth => _visibleMonth;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;

  /// Longest range, in days, that is expanded day by day.
  // TODO(DP-079): 14 is an assumption; exhibitions longer than this stay on their start day.
  static const maxExpandedDays = 14;

  /// Number of days of a short multi-day [activity], or null when it is a
  /// single-day plan or too long to be expanded.
  static int? spanDays(Activity activity) {
    final end = activity.endsAt;
    if (end == null) return null;
    final start = _dateOnly(activity.startsAt);
    final days = _dateOnly(end).difference(start).inDays + 1;
    return days > 1 && days <= maxExpandedDays ? days : null;
  }

  /// «Dia X de N» position of [activity] on [day], or null for one-day plans.
  ({int day, int of})? dayPosition(Activity activity, DateTime day) {
    final total = spanDays(activity);
    if (total == null) return null;
    final index = _dateOnly(day)
        .difference(_dateOnly(activity.startsAt))
        .inDays;
    return index < 0 || index >= total ? null : (day: index + 1, of: total);
  }

  bool hasPlansOn(DateTime day) => _plansByDay.containsKey(_dateOnly(day));

  bool get hasAnyPlans => _plansByDay.isNotEmpty;

  /// Plans of [day], ordered by start time.
  List<Activity> plansOn(DateTime day) =>
      _plansByDay[_dateOnly(day)] ?? const [];

  /// Plans of the selected day, ordered by start time.
  List<Activity> get selectedDayPlans => _plansByDay[_selectedDay] ?? const [];

  /// Upcoming signed-up plans (from [today] onwards), grouped by day in
  /// chronological order.
  // TODO(DP-079): today stays in upcoming so same-day events (including
  // midnight backend dates per DP-029) and rating blocks remain directly
  // visible below the calendar.
  List<AgendaDayGroup> get upcomingPlanGroups =>
      _groups(upcoming: true, newestFirst: false);

  /// A plan is still "upcoming" if it starts today or later, or it started
  /// earlier but has not ended yet (exhibitions, festivals).
  bool _isUpcoming(Activity plan, DateTime day, DateTime currentDay) {
    if (!day.isBefore(currentDay)) return true;
    // Expanded plans: each day counts by itself.
    if (spanDays(plan) != null) return false;
    final end = plan.endsAt;
    return end != null && !_dateOnly(end).isBefore(currentDay);
  }

  List<AgendaDayGroup> _groups({
    required bool upcoming,
    required bool newestFirst,
  }) {
    final currentDay = today;
    final days = _plansByDay.keys.toList()
      ..sort((a, b) => newestFirst ? b.compareTo(a) : a.compareTo(b));
    return List.unmodifiable([
      for (final day in days)
        if ([
              for (final p in _plansByDay[day]!)
                if (_isUpcoming(p, day, currentDay) == upcoming) p,
            ]
            case final plans when plans.isNotEmpty)
          AgendaDayGroup(day: day, plans: plans),
    ]);
  }

  /// All upcoming signed-up plans (from [today] onwards), ordered by date and
  /// start time.
  List<Activity> get upcomingPlans => List.unmodifiable([
    for (final group in upcomingPlanGroups) ...group.plans,
  ]);

  /// Past signed-up plans (strictly before [today]), grouped by day with the
  /// most recent day first.
  // TODO(DP-079): past days are grouped newest-first inside a collapsible
  // secondary section below upcoming plans.
  List<AgendaDayGroup> get pastPlanGroups =>
      _groups(upcoming: false, newestFirst: true);

  /// All past signed-up plans (strictly before [today]).
  List<Activity> get pastPlans =>
      List.unmodifiable([for (final group in pastPlanGroups) ...group.plans]);

  /// Plans that have already started, newest first, whatever day is
  /// selected: the ones «Com va anar?» asks about (#64, R8).
  List<Activity> get startedPlans {
    final now = _now();
    return List.unmodifiable(
      {
        for (final plans in _plansByDay.values)
          for (final plan in plans)
            if (activityHasStarted(plan, now)) plan.id: plan,
      }.values.toList()..sort((a, b) => b.startsAt.compareTo(a.startsAt)),
    );
  }

  void selectDay(DateTime day) {
    final date = _dateOnly(day);
    if (date == _selectedDay) return;
    _selectedDay = date;
    _visibleMonth = DateTime(date.year, date.month);
    notifyListeners();
  }

  void showPreviousMonth() => _showMonth(-1);

  void showNextMonth() => _showMonth(1);

  void _showMonth(int offset) {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    notifyListeners();
  }

  Future<void> load() async {
    if (_isDisposed || _isLoading) return;
    final version = ++_subscriptionVersion;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _subscription?.cancel();
      if (_isDisposed || version != _subscriptionVersion) return;
      _subscription = _enrollmentRepository
          .watchEnrolledActivityIds(userId)
          .listen(
            (ids) => _resolvePlans(ids, version),
            onError: (Object error, StackTrace stackTrace) => _fail(version),
            onDone: () => _fail(version),
          );
    } catch (_) {
      _fail(version);
    }
  }

  /// Reads the activities of the current plans again (e.g. after one of
  /// them has been edited): the cached copies may be out of date.
  Future<void> refreshActivities() async {
    if (_isDisposed || !_hasLoaded) return;
    _activityCache.clear();
    await _resolvePlans(_enrolledIds, _subscriptionVersion);
  }

  Future<void> _resolvePlans(Set<String> ids, int version) async {
    if (_isDisposed || version != _subscriptionVersion) return;
    _enrolledIds = ids;
    final request = ++_resolveRequest;
    try {
      final missing = ids.where((id) => !_activityCache.containsKey(id));
      final fetched = await Future.wait(
        missing.map(_activityRepository.getActivityById),
      );
      for (final activity in fetched) {
        if (activity != null) _activityCache[activity.id] = activity;
      }
      if (_isStale(version, request)) return;
    } catch (_) {
      if (_isStale(version, request)) return;
      _fail(version);
      return;
    }

    final plansByDay = <DateTime, List<Activity>>{};
    for (final id in ids) {
      final activity = _activityCache[id];
      if (activity == null) continue;
      // Short multi-day plans (festivals) show on every day of their range;
      // long ones (exhibitions) stay on their start day to keep lists short.
      final start = _dateOnly(activity.startsAt);
      for (var i = 0; i < (spanDays(activity) ?? 1); i++) {
        plansByDay
            .putIfAbsent(
              DateTime(start.year, start.month, start.day + i),
              () => [],
            )
            .add(activity);
      }
    }
    for (final plans in plansByDay.values) {
      plans.sort(_comparePlans);
    }
    _plansByDay = {
      for (final entry in plansByDay.entries)
        entry.key: List.unmodifiable(entry.value),
    };
    _isLoading = false;
    _hasLoaded = true;
    _errorMessage = null;
    notifyListeners();
  }

  bool _isStale(int version, int request) =>
      _isDisposed ||
      version != _subscriptionVersion ||
      request != _resolveRequest;

  void _fail(int version) {
    if (_isDisposed || version != _subscriptionVersion) return;
    _resolveRequest++;
    _isLoading = false;
    _errorMessage = currentL10n.agendaLoadError;
    notifyListeners();
  }

  static int _comparePlans(Activity a, Activity b) {
    final timeA = activityStartTime(a) ?? a.startsAt;
    final timeB = activityStartTime(b) ?? b.startsAt;
    final byTime = timeA.compareTo(timeB);
    if (byTime != 0) return byTime;
    return a.id.compareTo(b.id);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  void dispose() {
    _isDisposed = true;
    _subscriptionVersion++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
