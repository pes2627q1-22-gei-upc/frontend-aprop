import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/agenda/presentation/screens/agenda_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../activities/fake_activity_repository.dart';
import '../activities/fake_enrollment_repository.dart';
import 'agenda_test_data.dart';

void main() {
  late FakeEnrollmentRepository enrollments;
  late FakeActivityRepository activities;
  late List<String> selectedActivities;

  setUp(() {
    enrollments = FakeEnrollmentRepository();
    activities = agendaActivityRepository();
    selectedActivities = [];
  });

  tearDown(() => enrollments.dispose());

  Future<void> pumpAgenda(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    Listenable? activitiesChanged,
  }) async {
    tester.view.physicalSize = size;
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
            onActivitySelected: selectedActivities.add,
            activitiesChanged: activitiesChanged,
            now: agendaToday,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder day(int month, int day) =>
      find.byKey(ValueKey('agenda-day-2026-$month-$day'));

  Finder dotOn(int month, int dayNumber) => find.descendant(
    of: day(month, dayNumber),
    matching: find.byKey(const ValueKey('agenda-plan-dot')),
  );

  testWidgets('Shows the month in Catalan with Monday-first weekdays', (
    tester,
  ) async {
    await pumpAgenda(tester);

    expect(find.text('Setembre de 2026'), findsOneWidget);
    for (final label in ['Dl', 'Dt', 'Dc', 'Dj', 'Dv', 'Ds', 'Dg']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Dissabte, 26 de setembre'), findsOneWidget);
    // 1 September 2026 is a Tuesday: second column.
    final mondayX = tester.getCenter(find.text('Dl')).dx;
    final tuesdayX = tester.getCenter(find.text('Dt')).dx;
    expect(tester.getCenter(day(9, 1)).dx, closeTo(tuesdayX, 1));
    expect(tester.getCenter(day(9, 7)).dx, closeTo(mondayX, 1));
  });

  testWidgets('Marks days with plans, today and the selected day', (
    tester,
  ) async {
    enrollments.emit(agendaUserId, {'jazz', 'theatre'});
    await pumpAgenda(tester);

    expect(dotOn(9, 26), findsOneWidget);
    expect(dotOn(9, 27), findsOneWidget);
    expect(dotOn(9, 28), findsNothing);
    expect(
      tester.getSemantics(day(9, 26)),
      matchesSemantics(
        label: 'Dissabte, 26 de setembre, avui, amb plans',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(day(9, 27));
    await tester.pump();
    expect(
      tester.getSemantics(day(9, 26)),
      matchesSemantics(
        label: 'Dissabte, 26 de setembre, avui, amb plans',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('Selecting a day updates its plans immediately', (tester) async {
    enrollments.emit(agendaUserId, {'jazz', 'cinema', 'theatre'});
    await pumpAgenda(tester);

    expect(find.text('Jazz'), findsOneWidget);
    expect(find.text('Activitat cinema'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Activitat cinema')).dy,
      lessThan(tester.getTopLeft(find.text('Jazz')).dy),
    );
    expect(find.text('11.00 h · Música'), findsOneWidget);
    expect(find.text('Font: Agenda Cultural · Generalitat'), findsNWidgets(2));
    expect(find.text('Apuntat'), findsNWidgets(2));

    await tester.tap(day(9, 27));
    await tester.pump();
    expect(find.text('Diumenge, 27 de setembre'), findsOneWidget);
    expect(find.text('Activitat theatre'), findsOneWidget);
    expect(find.text('Jazz'), findsNothing);
  });

  testWidgets('A day without plans shows a specific message', (tester) async {
    enrollments.emit(agendaUserId, {'jazz'});
    await pumpAgenda(tester);

    await tester.tap(day(9, 28));
    await tester.pump();
    expect(find.text('No tens cap pla per a aquest dia.'), findsOneWidget);
  });

  testWidgets('Navigates between months', (tester) async {
    enrollments.emit(agendaUserId, {'october'});
    await pumpAgenda(tester);

    await tester.tap(find.byTooltip('Mes següent'));
    await tester.pump();
    expect(find.text('Octubre de 2026'), findsOneWidget);
    expect(dotOn(10, 3), findsOneWidget);

    await tester.tap(day(10, 3));
    await tester.pump();
    expect(find.text('Dissabte, 3 d’octubre'), findsOneWidget);
    expect(find.text('Activitat october'), findsOneWidget);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pump();
    expect(find.text('Agost de 2026'), findsOneWidget);
  });

  testWidgets('Shows loading while plans are being read', (tester) async {
    enrollments.emit(agendaUserId, {'jazz'});
    activities.findActivity = (id) =>
        Future.delayed(const Duration(seconds: 1), () => agendaCatalogue[id]);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AgendaScreen(
            userId: agendaUserId,
            enrollmentRepository: enrollments,
            activityRepository: activities,
            onActivitySelected: selectedActivities.add,
            now: agendaToday,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Carregant la teva agenda'), findsOneWidget);
    expect(find.text('No tens cap pla per a aquest dia.'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Jazz'), findsOneWidget);
  });

  testWidgets('A read error offers a retry', (tester) async {
    enrollments.failReads = true;
    await pumpAgenda(tester);

    expect(
      find.text('No hem pogut carregar la teva agenda. Torna-ho a provar.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Mes següent'), findsOneWidget);

    enrollments.failReads = false;
    enrollments.emit(agendaUserId, {'jazz'});
    await tester.tap(find.text('Tornar-ho a provar'));
    // Stream cancellation crosses async zones; flush it before fake-time frames.
    await tester.runAsync(() async {});
    await tester.pumpAndSettle();
    expect(find.text('Jazz'), findsOneWidget);
  });

  testWidgets('Reloads the plans when an activity is edited', (tester) async {
    final activitiesChanged = ValueNotifier<int>(0);
    addTearDown(activitiesChanged.dispose);
    enrollments.emit(agendaUserId, {'jazz'});
    await pumpAgenda(tester, activitiesChanged: activitiesChanged);
    expect(find.text('Jazz'), findsOneWidget);

    activities.findActivity = (id) async => id == 'jazz'
        ? agendaActivity('jazz', DateTime(2026, 9, 26, 19), title: 'Jazz nou')
        : agendaCatalogue[id];
    activitiesChanged.value++;
    await tester.pumpAndSettle();

    expect(find.text('Jazz nou'), findsOneWidget);
    expect(find.text('Jazz'), findsNothing);
  });

  testWidgets('The image and the title open the activity', (tester) async {
    enrollments.emit(agendaUserId, {'jazz'});
    await pumpAgenda(tester);

    await tester.tap(find.text('Jazz'));
    await tester.tap(find.bySemanticsLabel('Veure activitat: Jazz'));
    expect(selectedActivities, ['jazz', 'jazz']);
  });

  testWidgets('Enlarged text on a narrow screen does not overflow', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    enrollments.emit(agendaUserId, {'jazz', 'cinema'});
    await pumpAgenda(tester, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Jazz'), 200);
    await tester.ensureVisible(find.text('Jazz'));
    await tester.pumpAndSettle();
    expect(find.text('Jazz').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
