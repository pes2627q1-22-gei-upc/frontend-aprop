import 'dart:async';

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/presentation/screens/activity_search_screen.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:aprop/features/profile/models/user_search_page.dart';
import 'package:aprop/features/profile/models/user_summary.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../profile/fake_user_search_repository.dart';
import 'fake_discovery_repository.dart';
import 'fake_enrollment_repository.dart';

const _person = UserSummary(
  id: 'marc',
  username: 'marcvidal',
  displayName: 'Marc Vidal',
);

void main() {
  late FakeUserSearchRepository users;
  late FakeDiscoveryRepository activities;
  late FakeEnrollmentRepository enrollments;
  late EnrollmentViewModel enrollment;
  String? opened;

  setUp(() async {
    users = FakeUserSearchRepository()..users = [_person];
    activities = FakeDiscoveryRepository();
    enrollments = FakeEnrollmentRepository();
    enrollment = EnrollmentViewModel(userId: 'viewer', repository: enrollments);
    await enrollment.load();
    opened = null;
  });
  tearDown(() async {
    enrollment.dispose();
    await enrollments.dispose();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
    String language = 'ca',
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: ActivitySearchScreen(
          repository: activities,
          userSearchRepository: users,
          enrollmentViewModel: enrollment,
          onActivitySelected: (_) {},
          onUserSelected: (id) => opened = id,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> people(WidgetTester tester) async {
    final context = tester.element(find.byType(ActivitySearchScreen));
    await tester.tap(find.text(AppLocalizations.of(context)!.actSegPeople));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String query) async {
    await tester.enterText(
      find.byKey(const ValueKey('activity-search-input')),
      query,
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
  }

  testWidgets(
    'People search shows prompt, loading, count and public identity',
    (tester) async {
      final pending = Completer<UserSearchPage>();
      users.onSearch = (_, _) => pending.future;
      await pumpScreen(tester);
      await people(tester);
      expect(find.text('A qui vols trobar?'), findsOneWidget);
      expect(users.requests, isEmpty);
      await submit(tester, 'marc');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(UserSearchPage(users: [_person], totalCount: 1));
      await tester.pumpAndSettle();
      expect(find.text('1 persona trobada'), findsOneWidget);
      expect(find.text('Marc Vidal'), findsOneWidget);
      expect(find.text('@marcvidal'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('user-search-marc')));
      expect(opened, 'marc');
      expect(enrollments.enrolledRequests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('People and activity modes keep the query and cached results', (
    tester,
  ) async {
    await pumpScreen(tester);
    await people(tester);
    await submit(tester, 'marc');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activitats'));
    await tester.pumpAndSettle();
    expect(find.text('Marc Vidal'), findsNothing);
    expect(activities.queries, ['marc']);
    await tester.tap(find.text('Persones'));
    await tester.pumpAndSettle();
    expect(find.text('Marc Vidal'), findsOneWidget);
    expect(users.requests, hasLength(1));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'marc',
    );
    await tester.tap(find.byTooltip('Esborrar la cerca'));
    await tester.pumpAndSettle();
    expect(find.text('A qui vols trobar?'), findsOneWidget);
    expect(find.text('Marc Vidal'), findsNothing);
    expect(users.requests, hasLength(1));
  });

  testWidgets(
    'Failure is retryable and differs from a successful empty result',
    (tester) async {
      users.onSearch = (_, _) async => throw StateError('Offline');
      await pumpScreen(tester);
      await people(tester);
      await submit(tester, 'missing');
      await tester.pumpAndSettle();
      expect(
        find.text('No hem pogut cercar persones. Torna-ho a provar.'),
        findsOneWidget,
      );
      expect(find.text('No hem trobat cap persona'), findsNothing);
      users.onSearch = null;
      users.users = [];
      await tester.tap(find.text('Tornar-ho a provar'));
      await tester.pumpAndSettle();
      expect(find.text('No hem trobat cap persona'), findsOneWidget);
      expect(find.text('0 persones trobades'), findsOneWidget);
    },
  );

  testWidgets('Pagination keeps people visible when loading more fails', (
    tester,
  ) async {
    var fail = true;
    users.onSearch = (_, page) async {
      if (page == 0) {
        return UserSearchPage(users: [_person], totalCount: 2, nextPage: 1);
      }
      if (fail) throw StateError('Offline');
      return UserSearchPage(
        users: [
          const UserSummary(
            id: 'julia',
            username: 'juliariera',
            displayName: 'Júlia Riera',
          ),
        ],
        totalCount: 2,
      );
    };
    await pumpScreen(tester);
    await people(tester);
    await submit(tester, 'a');
    await tester.pumpAndSettle();
    final more = find.byKey(const ValueKey('users-load-more'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('Marc Vidal'), findsOneWidget);
    expect(
      find.text('No hem pogut carregar més persones. Torna-ho a provar.'),
      findsOneWidget,
    );
    fail = false;
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('Júlia Riera'), findsOneWidget);
    expect(find.text('2 persones trobades'), findsOneWidget);
  });

  testWidgets('People search supports narrow screens and large text', (
    tester,
  ) async {
    users.users = [
      const UserSummary(
        id: 'long',
        username: 'un_nom_d_usuari_molt_llarg_per_a_una_pantalla_petita',
        displayName: 'Una persona amb un nom llarg i diversos cognoms',
      ),
    ];
    await pumpScreen(tester, width: 320, scale: 2);
    await people(tester);
    await submit(tester, 'nom');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('user-search-long')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['es', 'en']) {
    testWidgets('People search labels follow the $language locale', (
      tester,
    ) async {
      await pumpScreen(tester, language: language);
      await people(tester);
      await submit(tester, 'marc');
      await tester.pumpAndSettle();
      expect(
        find.text(language == 'es' ? '1 persona encontrada' : '1 person found'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
