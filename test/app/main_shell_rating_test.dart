import 'package:aprop/app/navigation/main_shell.dart';
import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/data/demo_enrollment_repository.dart';
import 'package:aprop/features/assistant/data/demo_assistant_repository.dart';
import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/activities/data/demo_discovery_repository.dart';
import 'package:aprop/features/notifications/data/demo_notification_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_settings_repository.dart';
import 'package:aprop/features/ratings/data/demo_rating_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// demo-jazz starts 2026-09-26 19:00.
Future<void> _pumpAgenda(
  WidgetTester tester, {
  required DateTime now,
  required bool enrolled,
  String activityId = 'demo-jazz',
  String? serverId,
  bool? attended,
}) async {
  final catalogue = DemoActivityRepository();
  final enrollment = DemoEnrollmentRepository(activityRepository: catalogue);
  addTearDown(enrollment.dispose);
  if (enrolled) {
    await enrollment.enroll(userId: serverId ?? 'u1', activityId: activityId);
  }
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MainShell(
        user: AppUser(
          id: 'u1',
          serverId: serverId,
          email: 'a@example.test',
          firstName: 'Test',
          lastName: 'User',
          username: 'test_user',
          emailVerified: true,
        ),
        onSignOut: () async {},
        activityRepository: catalogue,
        enrollmentRepository: enrollment,
        discoveryRepository: DemoDiscoveryRepository(
          activityRepository: catalogue,
        ),
        ratingRepository: DemoRatingRepository(),
        assistantRepository: DemoAssistantRepository(
          activityRepository: catalogue,
        ),
        notificationRepository: DemoNotificationRepository(
          activityRepository: catalogue,
        ),
        profileRepository: DemoProfileRepository(activityRepository: catalogue),
        profileSettingsRepository: DemoProfileSettingsRepository(),
        now: () => now,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Agenda'),
    ),
  );
  await tester.pumpAndSettle();
  // «Com va anar?» (#64): only who went can rate (R10).
  if (attended != null) {
    final answer = attended ? 'attendance-yes' : 'attendance-no';
    await tester.tap(find.byKey(ValueKey('$answer-$activityId')));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('stars are hidden when not enrolled', (tester) async {
    await _pumpAgenda(tester, now: DateTime(2026, 9, 26, 20), enrolled: false);
    expect(find.text('Com t’ha anat?'), findsNothing);
  });

  testWidgets('stars are hidden before the activity starts', (tester) async {
    await _pumpAgenda(tester, now: DateTime(2026, 9, 26, 18), enrolled: true);
    expect(find.text('Jazz al parc'), findsOneWidget);
    // Nor is «Com va anar?» asked yet (R8).
    expect(find.text('Com va anar?'), findsNothing);
    expect(find.text('Com t’ha anat?'), findsNothing);
  });

  testWidgets('stars appear only after «Sí, hi vaig anar»', (tester) async {
    await _pumpAgenda(tester, now: DateTime(2026, 9, 26, 20), enrolled: true);
    expect(find.text('Com va anar?'), findsOneWidget);
    expect(find.text('Com t’ha anat?'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('attendance-yes-demo-jazz')));
    await tester.pumpAndSettle();

    expect(find.text('Com va anar?'), findsNothing);
    expect(find.text('Com t’ha anat?'), findsOneWidget);
    expect(find.textContaining('organitzador'), findsNothing);
    // It says so: the stars may be on another day of the calendar.
    expect(
      find.text('Gràcies! Ja pots valorar «Jazz al parc».'),
      findsOneWidget,
    );
  });

  testWidgets('«Sí» i «No» es veuen igual i un al costat de l’altre', (
    tester,
  ) async {
    await _pumpAgenda(tester, now: DateTime(2026, 9, 26, 20), enrolled: true);
    final yes = find.byKey(const ValueKey('attendance-yes-demo-jazz'));
    final no = find.byKey(const ValueKey('attendance-no-demo-jazz'));

    expect(tester.getSize(yes), tester.getSize(no));
    expect(tester.getTopLeft(yes).dy, tester.getTopLeft(no).dy);
    final yesColor = tester
        .widget<FilledButton>(yes)
        .style!
        .backgroundColor!
        .resolve({});
    final noColor = tester
        .widget<FilledButton>(no)
        .style!
        .backgroundColor!
        .resolve({});
    // A background that is not the card's: the buttons can be seen.
    expect(yesColor, isNot(Theme.of(tester.element(yes)).colorScheme.surface));
    expect(yesColor, noColor);
  });

  testWidgets('«No hi vaig anar» closes the question without stars', (
    tester,
  ) async {
    await _pumpAgenda(
      tester,
      now: DateTime(2026, 9, 26, 20),
      enrolled: true,
      attended: false,
    );
    expect(find.text('Com va anar?'), findsNothing);
    expect(find.text('Com t’ha anat?'), findsNothing);
  });

  testWidgets('community plan highlights its organizer', (tester) async {
    // demo-theatre: community, created by Laia Soler (not u1), 2026-09-27 20:00.
    await _pumpAgenda(
      tester,
      now: DateTime(2026, 9, 27, 21),
      enrolled: true,
      activityId: 'demo-theatre',
      attended: true,
    );
    expect(
      find.text('Com ha anat l’organitzador/a Laia Soler?'),
      findsOneWidget,
    );
    expect(find.text('Com t’ha anat?'), findsNothing);
  });

  testWidgets('the organizer cannot rate their own event', (tester) async {
    // The creator id is the server id of the signed-in user, not its Firebase id.
    await _pumpAgenda(
      tester,
      now: DateTime(2026, 9, 27, 21),
      enrolled: true,
      activityId: 'demo-theatre',
      serverId: 'demo-laiasoler',
      attended: true,
    );
    expect(find.textContaining('organitzador'), findsNothing);
    expect(find.text('Com t’ha anat?'), findsNothing);
  });

  testWidgets('«Més tard» hides the question only until the next visit', (
    tester,
  ) async {
    await _pumpAgenda(tester, now: DateTime(2026, 9, 26, 20), enrolled: true);

    await tester.tap(find.byKey(const ValueKey('attendance-later-demo-jazz')));
    await tester.pumpAndSettle();
    expect(find.text('Com va anar?'), findsNothing);

    Finder destination(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );
    await tester.tap(destination('Inici'));
    await tester.pumpAndSettle();
    await tester.tap(destination('Agenda'));
    await tester.pumpAndSettle();

    expect(find.text('Com va anar?'), findsOneWidget);
  });

  testWidgets('The question fits 320 px with doubled text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpAgenda(tester, now: DateTime(2026, 9, 26, 20), enrolled: true);
    tester.view.physicalSize = const Size(320, 844);
    await tester.pumpAndSettle();

    expect(find.text('Com va anar?'), findsOneWidget);
    expect(find.text('Sí, hi vaig anar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
