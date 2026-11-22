import 'dart:async';

import 'package:aprop/app/navigation/activity_details_route.dart';
import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/presentation/formatters/activity_date_formatter.dart';
import 'package:aprop/features/activities/presentation/screens/activity_details_screen.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_badges.dart';
import 'package:aprop/features/activities/repositories/activity_repository.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_activity_repository.dart';
import 'fake_enrollment_repository.dart';

void main() {
  Future<void> pumpDetails(
    WidgetTester tester, {
    String id = 'demo-jazz',
    ActivityRepository? repository,
    double textScale = 1,
    Future<bool> Function(Uri uri)? openLink,
    Set<String> enrolled = const {},
    void Function(Activity activity)? onOpenChat,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final enrollments = FakeEnrollmentRepository()..emit('test-user', enrolled);
    final enrollmentViewModel = EnrollmentViewModel(
      userId: 'test-user',
      repository: enrollments,
    );
    enrollmentViewModel.load();
    addTearDown(() async {
      enrollmentViewModel.dispose();
      await enrollments.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: ActivityDetailsScreen(
          activityId: id,
          repository: repository ?? DemoActivityRepository(),
          enrollmentViewModel: enrollmentViewModel,
          clock: () => DateTime(2026, 9, 26, 9),
          openLink: openLink ?? (uri) async => true,
          onOpenChat: onOpenChat,
        ),
      ),
    );
  }

  FakeActivityRepository extraInfoRepository() =>
      FakeActivityRepository()
        ..findActivity = (id) async => Activity(
          id: id,
          title: 'Xerrada sobre jazz',
          category: 'Música',
          categories: const ['Música', 'Conferències'],
          municipality: 'Girona',
          startsAt: DateTime(2026, 11, 14),
          endsAt: DateTime(2026, 11, 20),
          imageAsset: '',
          source: ActivitySource.culturalAgenda,
          schedule: 'De 18.00 a 19.30 h',
          modality: ActivityModality.mixed,
          isPermanent: true,
          tickets: 'Entrada lliure',
          email: 'info@example.cat',
          onlineUrl: 'https://meet.example.cat/jazz',
          website: 'https://auditori.cat/jazz',
          links: const [
            ActivityLink(name: 'Programa', url: 'https://auditori.cat/jazz'),
            ActivityLink(name: 'Fitxa', url: 'https://example.cat/fitxa'),
          ],
        );

  test('Demo details reuse catalogue IDs and handle unknown IDs', () async {
    final repository = DemoActivityRepository();
    for (final activity in await repository.getActivities()) {
      expect(await repository.getActivityById(activity.id), same(activity));
    }
    expect(await repository.getActivityById('missing'), isNull);
  });

  test('Date formatting includes the actual day and year on details', () {
    final date = DateTime(2026, 9, 26, 9, 5);
    expect(formatActivitySchedule(date), 'Dissabte · 09.05 h');
    expect(
      formatActivitySchedule(date, includeDate: true),
      'Dissabte 26 de setembre de 2026 · 09.05 h',
    );
    expect(
      formatActivitySchedule(DateTime(2026, 10, 20, 19), includeDate: true),
      'Dimarts 20 d’octubre de 2026 · 19.00 h',
    );
    expect(
      formatActivitySchedule(DateTime(2026, 4, 1, 19), includeDate: true),
      'Dimecres 1 d’abril de 2026 · 19.00 h',
    );
  });

  testWidgets('Shows loading until the detail request completes', (
    tester,
  ) async {
    final result = Completer<Activity?>();
    final repository = FakeActivityRepository()
      ..findActivity = (_) => result.future;
    await pumpDetails(tester, repository: repository);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    result.complete(
      await DemoActivityRepository().getActivityById('demo-jazz'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jazz al parc'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Shows official data and enables enrollment', (tester) async {
    await pumpDetails(tester);
    await tester.pumpAndSettle();

    expect(find.text('Jazz al parc'), findsOneWidget);
    expect(find.text('Barcelona'), findsOneWidget);
    expect(find.textContaining('26 de setembre de 2026'), findsOneWidget);
    expect(find.text('Publicat per'), findsNothing);
    final enroll = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'M’hi apunto'),
    );
    expect(enroll.onPressed, isNotNull);
    await tester.scrollUntilVisible(
      find.text('Font: Agenda Cultural · Generalitat'),
      200,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('El xat només està actiu per a qui s’hi ha apuntat (R11)', (
    tester,
  ) async {
    final opened = <String>[];
    await pumpDetails(
      tester,
      onOpenChat: (activity) => opened.add(activity.id),
    );
    await tester.pumpAndSettle();
    final chat = find.widgetWithText(OutlinedButton, 'Xat de l’activitat');
    await tester.scrollUntilVisible(chat, 200);

    expect(tester.widget<OutlinedButton>(chat).onPressed, isNull);
    expect(
      find.text('Apunta’t a l’activitat per poder parlar al xat.'),
      findsOneWidget,
    );
    expect(opened, isEmpty);
  });

  testWidgets('Amb la inscripció, el botó obre el xat de l’activitat', (
    tester,
  ) async {
    final opened = <String>[];
    await pumpDetails(
      tester,
      enrolled: {'demo-jazz'},
      onOpenChat: (activity) => opened.add(activity.id),
    );
    await tester.pumpAndSettle();
    final chat = find.widgetWithText(OutlinedButton, 'Xat de l’activitat');
    await tester.scrollUntilVisible(chat, 200);

    expect(
      find.text('Parla amb les persones que també s’hi han apuntat.'),
      findsOneWidget,
    );
    await tester.tap(chat);
    expect(opened, ['demo-jazz']);
  });

  testWidgets('Shows the community creator and friendship badge', (
    tester,
  ) async {
    await pumpDetails(tester, id: 'demo-theatre');
    await tester.pumpAndSettle();
    expect(find.text('Teatre sota les estrelles'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Laia Soler'), 150);
    expect(find.text('Publicat per'), findsOneWidget);
    expect(find.text('Amiga'), findsOneWidget);
    expect(find.text('Font: Agenda Cultural · Generalitat'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mostra totes les categories, l’horari i la informació extra', (
    tester,
  ) async {
    final repository = extraInfoRepository();
    final opened = <Uri>[];
    await pumpDetails(
      tester,
      id: '101',
      repository: repository,
      openLink: (uri) async {
        opened.add(uri);
        return true;
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('Música'), findsOneWidget);
    expect(find.text('Conferències'), findsOneWidget);
    // L'hora és la de l'«Horari», no les 00.00 h de la data.
    expect(find.textContaining('De 18.00 a 19.30 h'), findsOneWidget);
    expect(find.textContaining('00.00 h'), findsNothing);
    expect(find.text('Fins al 20 de novembre de 2026'), findsOneWidget);
    expect(find.text('Activitat permanent'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Presencial i en línia'), 150);
    expect(find.text('Entrada lliure'), findsOneWidget);
    expect(find.text('info@example.cat'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Fitxa'), 150);
    expect(find.text('Enllaç per connectar-s’hi'), findsOneWidget);
    expect(find.text('Web de l’activitat'), findsOneWidget);
    // La mateixa adreça no surt dues vegades.
    expect(find.text('Programa'), findsNothing);

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final copy = find.byTooltip('Copia l’enllaç: Fitxa');
    await tester.ensureVisible(copy);
    await tester.pumpAndSettle();
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(find.text('Enllaç copiat.'), findsOneWidget);
    expect(copied, 'https://example.cat/fitxa');

    // Tocar l'enllaç l'obre fora de l'app.
    await tester.ensureVisible(find.text('Fitxa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fitxa'));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('https://example.cat/fitxa')]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Si un enllaç no es pot obrir, ho diu', (tester) async {
    await pumpDetails(
      tester,
      id: '101',
      repository: extraInfoRepository(),
      openLink: (uri) async => false,
    );
    await tester.pumpAndSettle();

    final link = find.text('Web de l’activitat');
    await tester.scrollUntilVisible(link, 150);
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.text('No s’ha pogut obrir l’enllaç.'), findsOneWidget);
  });

  testWidgets('Sense hora coneguda, no mostra les 00.00 h', (tester) async {
    final repository = FakeActivityRepository()
      ..findActivity = (id) async => Activity(
        id: id,
        title: 'Exposició',
        category: 'Exposicions',
        municipality: 'Vic',
        startsAt: DateTime(2026, 11, 14),
        imageAsset: '',
        source: ActivitySource.culturalAgenda,
      );
    await pumpDetails(tester, id: '102', repository: repository);
    await tester.pumpAndSettle();

    expect(find.textContaining('14 de novembre de 2026'), findsOneWidget);
    expect(find.textContaining('00.00 h'), findsNothing);
    expect(find.text('Enllaços'), findsNothing);
  });

  testWidgets('Creator block shows the organizer reliability or a dash', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpDetails(tester, id: 'demo-theatre');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Laia Soler'), 150);
    expect(
      find.textContaining('Fiabilitat 4,7', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp('Fiabilitat de l’organitzador: 4,7 sobre 5'),
      ),
      findsOneWidget,
    );

    final unrated = (await DemoActivityRepository().getActivityById(
      'demo-theatre',
    ))!;
    final repository = FakeActivityRepository()
      ..findActivity = (_) async => Activity(
        id: unrated.id,
        title: unrated.title,
        category: unrated.category,
        municipality: unrated.municipality,
        startsAt: unrated.startsAt,
        imageAsset: unrated.imageAsset,
        source: ActivitySource.community,
        creator: const ActivityCreator(name: 'Pol', isFriend: false),
      );
    await pumpDetails(tester, id: 'demo-theatre', repository: repository);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Pol'), 150);
    expect(find.text('Fiabilitat —', findRichText: true), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('Fiabilitat de l’organitzador: sense valoracions'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('Unknown ID shows an honest not-found state', (tester) async {
    await pumpDetails(tester, id: 'missing');
    await tester.pumpAndSettle();
    expect(find.text('No hem trobat aquesta activitat.'), findsOneWidget);
    expect(find.text('M’hi apunto'), findsNothing);
  });

  testWidgets('Retry reloads the same activity after a failure', (
    tester,
  ) async {
    final repository = FakeActivityRepository()
      ..findActivity = (_) async => throw Exception('Offline');
    await pumpDetails(tester, repository: repository);
    await tester.pumpAndSettle();
    expect(find.textContaining('No hem pogut carregar'), findsOneWidget);

    repository.findActivity = (_) =>
        DemoActivityRepository().getActivityById('demo-jazz');
    await tester.tap(find.text('Tornar-ho a provar'));
    await tester.pumpAndSettle();
    expect(find.text('Jazz al parc'), findsOneWidget);
    expect(repository.requestedIds, ['demo-jazz', 'demo-jazz']);
  });

  testWidgets('Large text remains scrollable and the action stays visible', (
    tester,
  ) async {
    await pumpDetails(tester, id: 'demo-theatre', textScale: 2);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sobre l’activitat'), 200);
    expect(find.text('M’hi apunto').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Missing descriptions and images have fallbacks', (tester) async {
    final repository = FakeActivityRepository()
      ..findActivity = (_) async => Activity(
        id: 'no-description',
        title: 'Activitat de prova',
        category: 'Música',
        municipality: 'Barcelona',
        startsAt: DateTime(2026, 9, 26, 19),
        imageAsset: 'assets/images/missing.jpg',
        source: ActivitySource.culturalAgenda,
      );
    await pumpDetails(tester, id: 'no-description', repository: repository);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Encara no hi ha una descripció disponible.'),
      200,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('The shared route opens by ID without an activities list', (
    tester,
  ) async {
    final repository = FakeActivityRepository()
      ..findActivity = (_) =>
          DemoActivityRepository().getActivityById('demo-theatre');
    final enrollments = FakeEnrollmentRepository();
    final enrollmentViewModel = EnrollmentViewModel(
      userId: 'test-user',
      repository: enrollments,
    );
    enrollmentViewModel.load();
    addTearDown(() async {
      enrollmentViewModel.dispose();
      await enrollments.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                activityDetailsRoute(
                  activityId: 'demo-theatre',
                  repository: repository,
                  enrollmentViewModel: enrollmentViewModel,
                ),
              ),
              child: const Text('Obrir des de l’agenda'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Obrir des de l’agenda'));
    await tester.pumpAndSettle();
    expect(find.text('Teatre sota les estrelles'), findsOneWidget);
    expect(repository.listRequests, 0);
    await tester.tap(find.byTooltip('Tornar enrere'));
    await tester.pumpAndSettle();
    expect(find.text('Obrir des de l’agenda').hitTestable(), findsOneWidget);
  });

  testWidgets('Shows all detail categories without a +N badge', (tester) async {
    final repository = FakeActivityRepository()
      ..findActivity = (id) async => Activity(
        id: id,
        title: 'Gran festival',
        category: 'Llibres i lletres',
        categories: const [
          'Llibres i lletres',
          'Espectacles',
          'Any Gaudí',
          'Altres àmbits',
          'Concerts',
          'Cinema',
          'Teatre',
          'Dansa',
          'Òpera',
          'Màgia',
        ],
        municipality: 'Barcelona',
        startsAt: DateTime(2026, 11, 14),
        imageAsset: '',
        source: ActivitySource.culturalAgenda,
      );

    await pumpDetails(tester, id: '500', repository: repository);
    await tester.pumpAndSettle();

    expect(find.byType(ActivityCategoryBadge), findsNWidgets(10));
    expect(find.text('Llibres i lletres'), findsOneWidget);
    expect(find.text('Espectacles'), findsOneWidget);
    expect(find.text('Any Gaudí'), findsOneWidget);
    expect(find.text('Altres àmbits'), findsOneWidget);
    expect(find.text('Màgia'), findsOneWidget);
    expect(find.byType(ActivityCategoryOverflowBadge), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Detail screen shows 3 chips without +N and localizes in English',
    (tester) async {
      final repository = FakeActivityRepository()
        ..findActivity = (id) async => Activity(
          id: id,
          title: 'Gala',
          category: 'Espectacles',
          categories: const ['Espectacles', 'Any Gaudí', 'Altres àmbits'],
          municipality: 'Barcelona',
          startsAt: DateTime(2026, 11, 14),
          imageAsset: '',
          source: ActivitySource.culturalAgenda,
        );
      final enrollments = FakeEnrollmentRepository();
      final enrollmentViewModel = EnrollmentViewModel(
        userId: 'test-user',
        repository: enrollments,
      )..load();
      addTearDown(() async {
        enrollmentViewModel.dispose();
        await enrollments.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ActivityDetailsScreen(
            activityId: '501',
            repository: repository,
            enrollmentViewModel: enrollmentViewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActivityCategoryBadge), findsNWidgets(3));
      expect(find.text('Performing arts'), findsOneWidget);
      expect(find.text('Gaudí Year'), findsOneWidget);
      expect(find.text('Other fields'), findsOneWidget);
      expect(find.byType(ActivityCategoryOverflowBadge), findsNothing);
    },
  );
}
