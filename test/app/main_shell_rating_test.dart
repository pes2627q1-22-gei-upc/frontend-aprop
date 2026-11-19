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
}

void main() {
  testWidgets('stars are hidden when not enrolled', (tester) async {
    await _pumpAgenda(tester, now: DateTime(2026, 9, 26, 20), enrolled: false);
    expect(find.text('Com t’ha anat?'), findsNothing);
  });

  testWidgets('stars are hidden before the activity starts', (tester) async {
    await _pumpAgenda(tester, now: DateTime(2026, 9, 26, 18), enrolled: true);
    expect(find.text('Jazz al parc'), findsOneWidget);
    expect(find.text('Com t’ha anat?'), findsNothing);
  });

  testWidgets('stars are shown when enrolled and started', (tester) async {
    await _pumpAgenda(tester, now: DateTime(2026, 9, 26, 20), enrolled: true);
    expect(find.text('Com t’ha anat?'), findsOneWidget);
    expect(find.textContaining('organitzador'), findsNothing);
  });

  testWidgets('community plan highlights its organizer', (tester) async {
    // demo-theatre: community, created by Laia Soler (not u1), 2026-09-27 20:00.
    await _pumpAgenda(
      tester,
      now: DateTime(2026, 9, 27, 21),
      enrolled: true,
      activityId: 'demo-theatre',
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
    );
    expect(find.textContaining('organitzador'), findsNothing);
    expect(find.text('Com t’ha anat?'), findsNothing);
  });
}
