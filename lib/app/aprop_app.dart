import 'package:flutter/material.dart';

import '../features/activities/repositories/activity_category_repository.dart';
import '../features/activities/repositories/activity_map_repository.dart';
import '../features/activities/repositories/activity_repository.dart';
import '../features/activities/repositories/discovery_repository.dart';
import '../features/activities/repositories/enrollment_repository.dart';
import '../features/activities/repositories/user_location_repository.dart';
import '../features/ratings/repositories/rating_repository.dart';
import '../features/assistant/repositories/assistant_repository.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../features/interest_test/repositories/interest_test_repository.dart';
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
    this.ratingRepository,
    this.notificationRepository,
    this.discoveryRepository,
    this.profileRepository,
    this.profileSettingsRepository,
    this.interestTestRepository,
    this.activityCategoryRepository,
    this.userLocationRepository,
  });

  final AuthRepository authRepository;

  /// On és la persona, per al mapa d'Inici. Sense, el mapa no la mostra.
  final UserLocationRepository? userLocationRepository;
  final ActivityRepository? activityRepository;
  final ActivityMapRepository? activityMapRepository;
  final EnrollmentRepository? enrollmentRepository;
  final AssistantRepository? assistantRepository;
  final RatingRepository? ratingRepository;
  final NotificationRepository? notificationRepository;
  final DiscoveryRepository? discoveryRepository;
  final ProfileRepository? profileRepository;
  final ProfileSettingsRepository? profileSettingsRepository;
  final InterestTestRepository? interestTestRepository;

  /// Categories per crear activitats. Si no hi és, el formulari fa servir la
  /// llista provisional.
  final ActivityCategoryRepository? activityCategoryRepository;

  @override
  Widget build(BuildContext context) {
    final authGate = AuthGate(
      key: ValueKey((
        authRepository,
        activityRepository,
        activityMapRepository,
        enrollmentRepository,
        assistantRepository,
        ratingRepository,
        notificationRepository,
        discoveryRepository,
        profileRepository,
        profileSettingsRepository,
        interestTestRepository,
        activityCategoryRepository,
        userLocationRepository,
      )),
      authRepository: authRepository,
      activityRepository: activityRepository,
      activityMapRepository: activityMapRepository,
      enrollmentRepository: enrollmentRepository,
      assistantRepository: assistantRepository,
      ratingRepository: ratingRepository,
      notificationRepository: notificationRepository,
      discoveryRepository: discoveryRepository,
      profileRepository: profileRepository,
      profileSettingsRepository: profileSettingsRepository,
      interestTestRepository: interestTestRepository,
      activityCategoryRepository: activityCategoryRepository,
      userLocationRepository: userLocationRepository,
    );

    return MaterialApp(
      title: 'AProp!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: authGate,
    );
  }
}
