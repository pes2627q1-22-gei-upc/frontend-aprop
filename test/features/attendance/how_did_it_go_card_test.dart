import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/agenda/presentation/screens/agenda_screen.dart';
import 'package:aprop/features/attendance/presentation/view_models/attendance_view_model.dart';
import 'package:aprop/features/attendance/repositories/attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../activities/fake_activity_repository.dart';
import '../activities/fake_enrollment_repository.dart';
import '../agenda/agenda_test_data.dart';

/// Nobody has answered yet: every started plan is asked about.
class _NoAnswers implements AttendanceRepository {
  @override
  Future<bool?> getAttendance({
    required String userId,
    required String activityId,
  }) async => null;

  @override
  Future<void> setAttendance({
    required String userId,
    required String activityId,
    required bool? attended,
  }) async {}
}

Activity _plan(String id, DateTime startsAt, {String? schedule}) => Activity(
  id: id,
  title: 'Pla $id',
  category: 'Música',
  municipality: 'Barcelona',
  startsAt: startsAt,
  imageAsset: 'assets/images/jazz_al_parc.jpg',
  source: ActivitySource.culturalAgenda,
  schedule: schedule,
);

/// «Com va anar?» in the Agenda (#64). «Today» is 26 September 2026, 9 h.
void main() {
  late FakeEnrollmentRepository enrollments;
  late FakeActivityRepository activities;
  late AttendanceViewModel attendance;

  setUp(() {
    enrollments = FakeEnrollmentRepository();
    activities = FakeActivityRepository();
    attendance = AttendanceViewModel(
      userId: agendaUserId,
      repository: _NoAnswers(),
    );
  });

  tearDown(() {
    attendance.dispose();
    enrollments.dispose();
  });

  Future<void> pumpAgenda(WidgetTester tester, List<Activity> plans) async {
    final byId = {for (final plan in plans) plan.id: plan};
    activities.findActivity = (id) async => byId[id];
    enrollments.emit(agendaUserId, byId.keys.toSet());
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AgendaScreen(
            userId: agendaUserId,
            enrollmentRepository: enrollments,
            activityRepository: activities,
            onActivitySelected: (_) {},
            attendanceViewModel: attendance,
            now: agendaToday,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder question(String id) => find.byKey(ValueKey('how-did-it-go-$id'));

  testWidgets('No pregunta per un pla d’avui que encara no ha començat', (
    tester,
  ) async {
    await pumpAgenda(tester, [
      // The backend keeps only the day (DP-029).
      _plan('no-hour', DateTime(2026, 9, 26)),
      _plan('tonight', DateTime(2026, 9, 26), schedule: 'A les 20 h'),
      _plan('this-morning', DateTime(2026, 9, 26), schedule: '8.30 h'),
      _plan('yesterday', DateTime(2026, 9, 25)),
    ]);

    expect(question('this-morning'), findsOneWidget);
    expect(question('yesterday'), findsOneWidget);
    expect(question('tonight'), findsNothing);
    expect(question('no-hour'), findsNothing);
  });

  testWidgets('Amb molts plans en mostra tres i la resta, en demanar-los', (
    tester,
  ) async {
    await pumpAgenda(tester, [
      for (var day = 20; day <= 24; day++)
        _plan('day-$day', DateTime(2026, 9, day, 19)),
    ]);

    // Newest first.
    expect(question('day-24'), findsOneWidget);
    expect(question('day-23'), findsOneWidget);
    expect(question('day-22'), findsOneWidget);
    expect(question('day-21'), findsNothing);
    expect(question('day-20'), findsNothing);

    await tester.tap(find.text('Veure’n 2 més'));
    await tester.pumpAndSettle();
    expect(question('day-21'), findsOneWidget);
    expect(question('day-20'), findsOneWidget);

    // Five questions do not fit: the button is further down.
    await tester.ensureVisible(find.text('Veure’n menys'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Veure’n menys'));
    await tester.pumpAndSettle();
    expect(question('day-21'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Amb tres plans o menys no hi ha «Veure’n més»', (tester) async {
    await pumpAgenda(tester, [
      for (var day = 22; day <= 24; day++)
        _plan('day-$day', DateTime(2026, 9, day, 19)),
    ]);

    expect(question('day-22'), findsOneWidget);
    expect(find.byKey(const ValueKey('how-did-it-go-more')), findsNothing);
  });
}
