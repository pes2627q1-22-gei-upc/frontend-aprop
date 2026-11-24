import 'dart:async';

import 'package:aprop/features/activities/models/activity.dart';
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
    expect(viewModel.hasAnyPlans, isFalse);
    expect(viewModel.upcomingPlanGroups, isEmpty);
    expect(viewModel.pastPlanGroups, isEmpty);
  });

  test('Loads own plans grouped by day and sorted by start time', () async {
    enrollments.emit(agendaUserId, {'jazz', 'cinema', 'theatre'});
    final load = viewModel.load();
    expect(viewModel.isLoading, isTrue);
    await load;
    await pumpEventQueue();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.hasLoaded, isTrue);
    expect(viewModel.hasAnyPlans, isTrue);
    expect(enrollments.watchedUsers, [agendaUserId]);
    expect(selectedIds(), ['cinema', 'jazz']);
    expect(viewModel.plansOn(DateTime(2026, 9, 27, 15)).map((a) => a.id), [
      'theatre',
    ]);
    expect(viewModel.plansOn(DateTime(2026, 9, 28)), isEmpty);
    expect(viewModel.hasPlansOn(DateTime(2026, 9, 26, 23)), isTrue);
    expect(viewModel.hasPlansOn(DateTime(2026, 9, 27)), isTrue);
    expect(viewModel.hasPlansOn(DateTime(2026, 9, 28)), isFalse);
  });

  test(
    'Splits upcoming plans chronologically and past plans newest-day first',
    () async {
      enrollments.emit(agendaUserId, {
        'next-year',
        'october',
        'jazz',
        'cinema',
        'theatre',
        'past-early',
        'past-recent',
      });
      await viewModel.load();
      await pumpEventQueue();

      expect(viewModel.upcomingPlanGroups.map((g) => g.day).toList(), [
        DateTime(2026, 9, 26),
        DateTime(2026, 9, 27),
        DateTime(2026, 10, 3),
        DateTime(2027, 1, 15),
      ]);
      expect(viewModel.upcomingPlans.map((a) => a.id).toList(), [
        'cinema',
        'jazz',
        'theatre',
        'october',
        'next-year',
      ]);

      expect(viewModel.pastPlanGroups.map((g) => g.day).toList(), [
        DateTime(2026, 9, 25),
        DateTime(2026, 9, 10),
      ]);
      expect(viewModel.pastPlans.map((a) => a.id).toList(), [
        'past-recent',
        'past-early',
      ]);
    },
  );

  test(
    'Keeps earlier-today plans in upcoming so same-day events stay visible',
    () async {
      final earlierToday = agendaActivity(
        'earlier-today',
        DateTime(2026, 9, 26, 7, 30),
        title: 'Matinal',
      );
      activities.findActivity = (id) async =>
          id == 'earlier-today' ? earlierToday : agendaCatalogue[id];
      enrollments.emit(agendaUserId, {'earlier-today', 'past-recent'});
      await viewModel.load();
      await pumpEventQueue();

      expect(viewModel.upcomingPlans.map((a) => a.id), ['earlier-today']);
      expect(viewModel.pastPlans.map((a) => a.id), ['past-recent']);
    },
  );

  test('Orders same-day midnight backend plans by schedule hour', () async {
    final evening = agendaActivity(
      'evening',
      DateTime(2026, 9, 26),
      schedule: 'A les 20 h',
    );
    final morning = agendaActivity(
      'morning',
      DateTime(2026, 9, 26),
      schedule: '10.30 h',
    );
    activities.findActivity = (id) async => switch (id) {
      'evening' => evening,
      'morning' => morning,
      _ => null,
    };
    enrollments.emit(agendaUserId, {'evening', 'morning'});
    await viewModel.load();
    await pumpEventQueue();

    expect(viewModel.plansOn(DateTime(2026, 9, 26)).map((a) => a.id), [
      'morning',
      'evening',
    ]);
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

  test(
    'New enrollments and removals update upcoming and past lists live',
    () async {
      await viewModel.load();
      await pumpEventQueue();
      expect(viewModel.selectedDayPlans, isEmpty);
      expect(viewModel.hasAnyPlans, isFalse);

      enrollments.emit(agendaUserId, {'jazz', 'past-recent'});
      await pumpEventQueue();
      expect(selectedIds(), ['jazz']);
      expect(viewModel.upcomingPlans.map((a) => a.id), ['jazz']);
      expect(viewModel.pastPlans.map((a) => a.id), ['past-recent']);
      expect(activities.requestedIds, ['jazz', 'past-recent']);

      enrollments.emit(agendaUserId, {'jazz', 'cinema', 'october'});
      await pumpEventQueue();
      expect(selectedIds(), ['cinema', 'jazz']);
      expect(viewModel.upcomingPlans.map((a) => a.id), [
        'cinema',
        'jazz',
        'october',
      ]);
      expect(viewModel.pastPlans, isEmpty);
      expect(activities.requestedIds, [
        'jazz',
        'past-recent',
        'cinema',
        'october',
      ]);
    },
  );

  test('Skips enrollments whose activity no longer exists', () async {
    enrollments.emit(agendaUserId, {'jazz', 'deleted'});
    await viewModel.load();
    await pumpEventQueue();
    expect(selectedIds(), ['jazz']);
    expect(viewModel.upcomingPlans.map((a) => a.id), ['jazz']);
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
    expect(viewModel.upcomingPlans.map((a) => a.id), ['jazz']);
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

  test('A short multi-day plan shows on every day with its position', () async {
    final festival = Activity(
      id: 'fest',
      title: 'Festival',
      category: 'Música',
      municipality: 'Barcelona',
      startsAt: DateTime(2026, 9, 27, 18),
      endsAt: DateTime(2026, 9, 28, 23),
      imageAsset: 'assets/images/jazz_al_parc.jpg',
      source: ActivitySource.culturalAgenda,
    );
    activities.findActivity = (id) async => id == 'fest' ? festival : null;
    enrollments.emit(agendaUserId, {'fest'});
    await viewModel.load();
    await pumpEventQueue();

    expect(viewModel.hasPlansOn(DateTime(2026, 9, 27)), isTrue);
    expect(viewModel.hasPlansOn(DateTime(2026, 9, 28)), isTrue);
    expect(viewModel.dayPosition(festival, DateTime(2026, 9, 28)), (
      day: 2,
      of: 2,
    ));
    expect(viewModel.upcomingPlans.length, 2);
    expect(viewModel.startedPlans.length, lessThanOrEqualTo(1));
  });
}
