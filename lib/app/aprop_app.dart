import 'package:flutter/material.dart';

import '../features/activities/repositories/activity_category_repository.dart';
import '../features/activities/repositories/activity_map_repository.dart';
import '../features/activities/repositories/activity_repository.dart';
import '../features/activities/repositories/discovery_repository.dart';
import '../features/activities/repositories/enrollment_repository.dart';
import '../features/assistant/repositories/assistant_repository.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../features/notifications/repositories/notification_repository.dart';
import '../features/profile/repositories/profile_repository.dart';
import '../features/profile/repositories/profile_settings_repository.dart';
import 'navigation/auth_gate.dart';
import 'theme/app_theme.dart';

class APropApp extends StatelessWidget {
  const APropApp({
    super.key,
    required this.authRepository,
    this.activityRepository,
    this.activityMapRepository,
    this.enrollmentRepository,
    this.assistantRepository,
    this.notificationRepository,
    this.discoveryRepository,
    this.profileRepository,
    this.profileSettingsRepository,
    this.activityCategoryRepository,
  });

  final AuthRepository authRepository;
  final ActivityRepository? activityRepository;
  final ActivityMapRepository? activityMapRepository;
  final EnrollmentRepository? enrollmentRepository;
  final AssistantRepository? assistantRepository;
  final NotificationRepository? notificationRepository;
  final DiscoveryRepository? discoveryRepository;
  final ProfileRepository? profileRepository;
  final ProfileSettingsRepository? profileSettingsRepository;

  /// Categories per crear activitats. Si no hi és, el formulari fa servir la
  /// llista provisional.
  final ActivityCategoryRepository? activityCategoryRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AProp!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AuthGate(
        key: ValueKey((
          authRepository,
          activityRepository,
          activityMapRepository,
          enrollmentRepository,
          assistantRepository,
          notificationRepository,
          discoveryRepository,
          profileRepository,
          profileSettingsRepository,
          activityCategoryRepository,
        )),
        authRepository: authRepository,
        activityRepository: activityRepository,
        activityMapRepository: activityMapRepository,
        enrollmentRepository: enrollmentRepository,
        assistantRepository: assistantRepository,
        notificationRepository: notificationRepository,
        discoveryRepository: discoveryRepository,
        profileRepository: profileRepository,
        profileSettingsRepository: profileSettingsRepository,
        activityCategoryRepository: activityCategoryRepository,
      ),
    );
  }
}
