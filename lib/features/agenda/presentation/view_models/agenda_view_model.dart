import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../activities/models/activity.dart';
import '../../../activities/repositories/activity_repository.dart';
import '../../../activities/repositories/enrollment_repository.dart';
import '../../../../core/l10n/locale_controller.dart';

/// Month calendar of the signed-in user's own plans (confirmed enrollments).
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

  bool hasPlansOn(DateTime day) => _plansByDay.containsKey(_dateOnly(day));

  /// Plans of the selected day, ordered by start time.
  List<Activity> get selectedDayPlans => _plansByDay[_selectedDay] ?? const [];

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
      plansByDay
          .putIfAbsent(_dateOnly(activity.startsAt), () => [])
          .add(activity);
    }
    for (final plans in plansByDay.values) {
      plans.sort((a, b) => a.startsAt.compareTo(b.startsAt));
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
