import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:aprop/features/agenda/presentation/screens/agenda_screen.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    Locale locale = LocaleController.defaultLocale,
  }) async {
    final previousLocale = LocaleController.active;
    LocaleController.active = locale;
    addTearDown(() => LocaleController.active = previousLocale);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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

  Finder daySheet() => find.byKey(const ValueKey('agenda-day-sheet'));

  testWidgets('Shows the month in Catalan with Monday-first weekdays', (
    tester,
  ) async {
    await pumpAgenda(tester);

    expect(find.text('Setembre de 2026'), findsOneWidget);
    for (final label in ['Dl', 'Dt', 'Dc', 'Dj', 'Dv', 'Ds', 'Dg']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Propers plans'), findsOneWidget);
    expect(find.text('Encara no t’has apuntat a cap pla.'), findsOneWidget);
    // 1 September 2026 is a Tuesday: second column.
    final mondayX = tester.getCenter(find.text('Dl')).dx;
    final tuesdayX = tester.getCenter(find.text('Dt')).dx;
    expect(tester.getCenter(day(9, 1)).dx, closeTo(tuesdayX, 1));
    expect(tester.getCenter(day(9, 7)).dx, closeTo(mondayX, 1));
  });

  testWidgets('Marks days with plans, today and the selected day', (
    tester,
  ) async {
    enrollments.emit(agendaUserId, {'jazz', 'theatre', 'past-recent'});
    await pumpAgenda(tester);

    expect(dotOn(9, 25), findsOneWidget);
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
    await tester.pumpAndSettle();
    // Dismiss the opened day modal sheet to check the calendar selection state.
    await tester.tap(find.byTooltip('Tancar els plans del dia'));
    await tester.pumpAndSettle();

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

  testWidgets(
    'Lists all upcoming plans below the calendar grouped by date in order',
    (tester) async {
      enrollments.emit(agendaUserId, {
        'october',
        'theatre',
        'jazz',
        'cinema',
        'next-year',
      });
      await pumpAgenda(tester, size: const Size(390, 2000));

      expect(find.text('Propers plans'), findsOneWidget);
      expect(find.text('Dissabte, 26 de setembre'), findsOneWidget);
      expect(find.text('Diumenge, 27 de setembre'), findsOneWidget);
      expect(find.text('Dissabte, 3 d’octubre'), findsOneWidget);
      expect(find.text('Divendres 15 de gener de 2027'), findsOneWidget);

      expect(find.text('Activitat cinema'), findsOneWidget);
      expect(find.text('Jazz'), findsOneWidget);
      expect(find.text('Activitat theatre'), findsOneWidget);
      expect(find.text('Activitat october'), findsOneWidget);
      expect(find.text('Festival d’hivern'), findsOneWidget);

      expect(
        tester.getTopLeft(find.text('Activitat cinema')).dy,
        lessThan(tester.getTopLeft(find.text('Jazz')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Jazz')).dy,
        lessThan(tester.getTopLeft(find.text('Activitat theatre')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Activitat theatre')).dy,
        lessThan(tester.getTopLeft(find.text('Activitat october')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Activitat october')).dy,
        lessThan(tester.getTopLeft(find.text('Festival d’hivern')).dy),
      );
      expect(find.text('11.00 h · Música'), findsOneWidget);
      expect(
        find.text('Font: Agenda Cultural · Generalitat'),
        findsNWidgets(5),
      );
      expect(find.text('Apuntat'), findsNWidgets(5));
    },
  );

  testWidgets(
    'Shows past plans in a collapsed secondary section that expands on tap',
    (tester) async {
      enrollments.emit(agendaUserId, {'jazz', 'past-early', 'past-recent'});
      await pumpAgenda(tester, size: const Size(390, 1400));

      expect(find.text('Jazz'), findsOneWidget);
      expect(find.text('Plans passats (2)'), findsOneWidget);
      expect(find.text('Exposició d’ahir'), findsNothing);
      expect(find.text('Concert antic'), findsNothing);

      final toggle = find.byKey(const ValueKey('agenda-past-toggle'));
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(find.text('Exposició d’ahir'), findsOneWidget);
      expect(find.text('Concert antic'), findsOneWidget);
      // Most recent past day first.
      expect(
        tester.getTopLeft(find.text('Exposició d’ahir')).dy,
        lessThan(tester.getTopLeft(find.text('Concert antic')).dy),
      );

      await tester.tap(find.text('Exposició d’ahir'));
      expect(selectedActivities, ['past-recent']);

      // Collapses again.
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text('Exposició d’ahir'), findsNothing);
    },
  );

  testWidgets(
    'Shows upcoming empty state alongside collapsed past plans when only past plans exist',
    (tester) async {
      enrollments.emit(agendaUserId, {'past-recent'});
      await pumpAgenda(tester);

      expect(find.text('No tens cap pla proper.'), findsOneWidget);
      expect(find.text('Plans passats (1)'), findsOneWidget);
      expect(find.text('Exposició d’ahir'), findsNothing);
    },
  );

  testWidgets(
    'Tapping a day opens a modal bottom sheet listing only that day’s plans and opens details on tap',
    (tester) async {
      enrollments.emit(agendaUserId, {'jazz', 'cinema', 'theatre'});
      await pumpAgenda(tester);

      await tester.tap(day(9, 27));
      await tester.pumpAndSettle();

      expect(daySheet(), findsOneWidget);
      expect(
        find.descendant(
          of: daySheet(),
          matching: find.text('Diumenge, 27 de setembre'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: daySheet(),
          matching: find.text('Activitat theatre'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: daySheet(), matching: find.text('Jazz')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: daySheet(),
          matching: find.text('Activitat cinema'),
        ),
        findsNothing,
      );

      await tester.tap(
        find.descendant(
          of: daySheet(),
          matching: find.text('Activitat theatre'),
        ),
      );
      await tester.pumpAndSettle();

      expect(daySheet(), findsNothing);
      expect(selectedActivities, ['theatre']);
    },
  );

  testWidgets('Tapping today (already selected) still opens the day sheet', (
    tester,
  ) async {
    enrollments.emit(agendaUserId, {'jazz'});
    await pumpAgenda(tester);

    await tester.tap(day(9, 26));
    await tester.pumpAndSettle();

    expect(daySheet(), findsOneWidget);
    expect(
      find.descendant(of: daySheet(), matching: find.text('Jazz')),
      findsOneWidget,
    );
  });

  testWidgets(
    'Tapping a day without plans opens the sheet with an empty note',
    (tester) async {
      enrollments.emit(agendaUserId, {'jazz'});
      await pumpAgenda(tester);

      await tester.tap(day(9, 28));
      await tester.pumpAndSettle();

      expect(daySheet(), findsOneWidget);
      expect(
        find.descendant(
          of: daySheet(),
          matching: find.text('No tens cap pla per a aquest dia.'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Tancar els plans del dia'));
      await tester.pumpAndSettle();
      expect(daySheet(), findsNothing);
      expect(selectedActivities, isEmpty);
    },
  );

  testWidgets('Navigates between months and opens that month’s day sheet', (
    tester,
  ) async {
    enrollments.emit(agendaUserId, {'october'});
    await pumpAgenda(tester);

    await tester.tap(find.byTooltip('Mes següent'));
    await tester.pump();
    expect(find.text('Octubre de 2026'), findsOneWidget);
    expect(dotOn(10, 3), findsOneWidget);

    await tester.tap(day(10, 3));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: daySheet(),
        matching: find.text('Dissabte, 3 d’octubre'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: daySheet(), matching: find.text('Activitat october')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Tancar els plans del dia'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pump();
    expect(find.text('Agost de 2026'), findsOneWidget);
  });

  testWidgets('Open day sheet updates live when enrollments change', (
    tester,
  ) async {
    enrollments.emit(agendaUserId, {'jazz'});
    await pumpAgenda(tester);

    await tester.tap(day(9, 26));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: daySheet(), matching: find.text('Jazz')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: daySheet(), matching: find.text('Activitat cinema')),
      findsNothing,
    );

    enrollments.emit(agendaUserId, {'jazz', 'cinema'});
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: daySheet(), matching: find.text('Activitat cinema')),
      findsOneWidget,
    );
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
    expect(find.text('Encara no t’has apuntat a cap pla.'), findsNothing);
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

  testWidgets(
    'The image and the title in the upcoming list open the activity',
    (tester) async {
      enrollments.emit(agendaUserId, {'jazz'});
      await pumpAgenda(tester);

      await tester.tap(find.text('Jazz'));
      await tester.tap(find.bySemanticsLabel('Veure activitat: Jazz'));
      expect(selectedActivities, ['jazz', 'jazz']);
    },
  );

  testWidgets('Localizes new Agenda strings in Spanish and English', (
    tester,
  ) async {
    enrollments.emit(agendaUserId, {'past-recent'});

    await pumpAgenda(tester, locale: const Locale('es'));
    expect(find.text('Próximos planes'), findsOneWidget);
    expect(find.text('No tienes ningún plan próximo.'), findsOneWidget);
    expect(find.text('Planes pasados (1)'), findsOneWidget);
    await tester.tap(day(9, 28));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cerrar los planes del día'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar los planes del día'));
    await tester.pumpAndSettle();

    await pumpAgenda(tester, locale: const Locale('en'));
    expect(find.text('Upcoming plans'), findsOneWidget);
    expect(find.text('You have no upcoming plans.'), findsOneWidget);
    expect(find.text('Past plans (1)'), findsOneWidget);
    await tester.tap(day(9, 28));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close day plans'), findsOneWidget);
  });

  testWidgets(
    'Enlarged text on a narrow screen does not overflow on list or day sheet',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      enrollments.emit(agendaUserId, {'jazz', 'cinema', 'past-recent'});
      await pumpAgenda(tester, size: const Size(320, 640));

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Jazz'), 200);
      await tester.ensureVisible(find.text('Jazz'));
      await tester.pumpAndSettle();
      expect(find.text('Jazz').hitTestable(), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('agenda-past-toggle')),
        200,
      );
      await tester.tap(find.byKey(const ValueKey('agenda-past-toggle')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Scroll back to calendar and open day sheet with doubled text.
      await tester.scrollUntilVisible(day(9, 26), -200);
      await tester.tap(day(9, 26));
      await tester.pumpAndSettle();
      expect(daySheet(), findsOneWidget);
      expect(
        find.descendant(of: daySheet(), matching: find.text('Jazz')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
