import 'dart:async';

import 'package:aprop/features/agenda/presentation/view_models/agenda_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../activities/fake_activity_repository.dart';
import '../activities/fake_enrollment_repository.dart';
import 'agenda_test_data.dart';

void main() {
  late FakeEnrollmentRepository enrollments;
  late FakeActivityRepository activities;
  late AgendaViewModel viewModel;

  setUp(() {
    enrollments = FakeEnrollmentRepository();
    activities = agendaActivityRepository();
    viewModel = AgendaViewModel(
      userId: agendaUserId,
      enrollmentRepository: enrollments,
      activityRepository: activities,
      now: agendaToday,
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await enrollments.dispose();
  });

  List<String> selectedIds() =>
      viewModel.selectedDayPlans.map((activity) => activity.id).toList();

  test('Starts on today and its month', () {
    expect(viewModel.today, DateTime(2026, 9, 26));
    expect(viewModel.selectedDay, DateTime(2026, 9, 26));
    expect(viewModel.visibleMonth, DateTime(2026, 9));
    expect(viewModel.hasLoaded, isFalse);
  });

  test('Loads own plans grouped by day and sorted by start time', () async {
    enrollments.emit(agendaUserId, {'jazz', 'cinema', 'theatre'});
    final load = viewModel.load();
    expect(viewModel.isLoading, isTrue);
    await load;
    await pumpEventQueue();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.hasLoaded, isTrue);
    expect(enrollments.watchedUsers, [agendaUserId]);
    expect(selectedIds(), ['cinema', 'jazz']);
    expect(viewModel.hasPlansOn(DateTime(2026, 9, 26, 23)), isTrue);
    expect(viewModel.hasPlansOn(DateTime(2026, 9, 27)), isTrue);
    expect(viewModel.hasPlansOn(DateTime(2026, 9, 28)), isFalse);
  });

  test('Selecting a day updates its plans immediately', () async {
    enrollments.emit(agendaUserId, {'jazz', 'theatre'});
    await viewModel.load();
    await pumpEventQueue();
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    viewModel.selectDay(DateTime(2026, 9, 27));
    expect(selectedIds(), ['theatre']);
    viewModel.selectDay(DateTime(2026, 9, 28));
    expect(viewModel.selectedDayPlans, isEmpty);
    viewModel.selectDay(DateTime(2026, 9, 28, 12));
    expect(notifications, 2);
  });

  test('Navigates between months across years', () {
    viewModel.showNextMonth();
    expect(viewModel.visibleMonth, DateTime(2026, 10));
    for (var i = 0; i < 3; i++) {
      viewModel.showNextMonth();
    }
    expect(viewModel.visibleMonth, DateTime(2027, 1));
    viewModel.showPreviousMonth();
    expect(viewModel.visibleMonth, DateTime(2026, 12));
    expect(viewModel.selectedDay, DateTime(2026, 9, 26));
  });

  test('Selecting a day of another month shows that month', () {
    viewModel.selectDay(DateTime(2026, 10, 3));
    expect(viewModel.visibleMonth, DateTime(2026, 10));
  });

  test('New enrollments appear without reloading', () async {
    await viewModel.load();
    await pumpEventQueue();
    expect(viewModel.selectedDayPlans, isEmpty);

    enrollments.emit(agendaUserId, {'jazz'});
    await pumpEventQueue();
    expect(selectedIds(), ['jazz']);
    expect(activities.requestedIds, ['jazz']);

    enrollments.emit(agendaUserId, {'jazz', 'cinema'});
    await pumpEventQueue();
    expect(selectedIds(), ['cinema', 'jazz']);
    expect(activities.requestedIds, ['jazz', 'cinema']);
  });

  test('Skips enrollments whose activity no longer exists', () async {
    enrollments.emit(agendaUserId, {'jazz', 'deleted'});
    await viewModel.load();
    await pumpEventQueue();
    expect(selectedIds(), ['jazz']);
    expect(viewModel.errorMessage, isNull);
  });

  test('A read failure shows an error and retry recovers', () async {
    enrollments.failReads = true;
    await viewModel.load();
    await pumpEventQueue();
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, contains('No hem pogut carregar'));

    enrollments.failReads = false;
    enrollments.emit(agendaUserId, {'jazz'});
    await viewModel.load();
    await pumpEventQueue();
    expect(viewModel.errorMessage, isNull);
    expect(selectedIds(), ['jazz']);
  });

  test('An activity lookup failure shows an error', () async {
    activities.findActivity = (id) async => throw StateError('Offline');
    enrollments.emit(agendaUserId, {'jazz'});
    await viewModel.load();
    await pumpEventQueue();
    expect(viewModel.errorMessage, isNotNull);
    expect(viewModel.hasLoaded, isFalse);
  });

  test('Repeated loads while loading are ignored', () async {
    final first = viewModel.load();
    final second = viewModel.load();
    await Future.wait([first, second]);
    await pumpEventQueue();
    expect(enrollments.watchedUsers, [agendaUserId]);
  });

  test('Ignores lookups that complete after dispose', () async {
    final lookup = Completer<void>();
    activities.findActivity = (id) async {
      await lookup.future;
      return agendaCatalogue[id];
    };
    enrollments.emit(agendaUserId, {'jazz'});
    final disposed = AgendaViewModel(
      userId: agendaUserId,
      enrollmentRepository: enrollments,
      activityRepository: activities,
      now: agendaToday,
    );
    var notifications = 0;
    disposed.addListener(() => notifications++);
    await disposed.load();
    await pumpEventQueue();
    final beforeDispose = notifications;

    disposed.dispose();
    lookup.complete();
    await pumpEventQueue();
    expect(notifications, beforeDispose);
  });
}
