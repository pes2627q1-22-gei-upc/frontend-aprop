import 'package:aprop/app/navigation/main_shell.dart';
import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/data/demo_discovery_repository.dart';
import 'package:aprop/features/activities/data/demo_enrollment_repository.dart';
import 'package:aprop/features/activities/models/activity_filters.dart';
import 'package:aprop/features/activities/models/activity_page.dart';
import 'package:aprop/features/assistant/data/demo_assistant_repository.dart';
import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/notifications/data/demo_notification_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_settings_repository.dart';
import 'package:aprop/features/ratings/data/demo_rating_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingRepository extends DemoActivityRepository {
  int pageLoads = 0;

  @override
  Future<ActivityPage> getActivitiesPage({
    int page = 0,
    int pageSize = 50,
    ActivityFilters? filters,
  }) {
    pageLoads++;
    return super.getActivitiesPage(
      page: page,
      pageSize: pageSize,
      filters: filters,
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => LocaleController.active = LocaleController.defaultLocale);

  testWidgets('changing the language reloads the already loaded events', (
    tester,
  ) async {
    final catalogue = _CountingRepository();
    final enrollment = DemoEnrollmentRepository(activityRepository: catalogue);
    addTearDown(enrollment.dispose);
    final controller = LocaleController();
    await tester.pumpWidget(
      LocaleScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.light,
          home: MainShell(
            user: AppUser(
              id: 'u1',
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
            profileRepository: DemoProfileRepository(
              activityRepository: catalogue,
            ),
            profileSettingsRepository: DemoProfileSettingsRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = catalogue.pageLoads;
    expect(before, greaterThan(0));

    await controller.setLocale(const Locale('es'));
    await tester.pumpAndSettle();

    expect(catalogue.pageLoads, greaterThan(before));
  });
}
