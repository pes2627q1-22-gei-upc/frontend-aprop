import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/locale_controller.dart';
import '../features/activities/repositories/activity_category_repository.dart';
import '../features/activities/repositories/activity_map_repository.dart';
import '../features/activities/repositories/activity_repository.dart';
import '../features/activities/repositories/discovery_repository.dart';
import '../features/activities/repositories/enrollment_repository.dart';
import '../features/activities/repositories/user_location_repository.dart';
import '../features/activity_chat/repositories/activity_chat_repository.dart';
import '../features/assistant/repositories/assistant_repository.dart';
import '../features/attendance/repositories/attendance_repository.dart';
import '../features/auth/presentation/screens/language_selection_screen.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../features/interest_test/repositories/interest_test_onboarding_memory.dart';
import '../features/interest_test/repositories/interest_test_repository.dart';
import '../features/notifications/repositories/notification_repository.dart';
import '../features/profile/repositories/friends_repository.dart';
import '../features/profile/repositories/friendship_repository.dart';
import '../features/profile/repositories/profile_repository.dart';
import '../features/profile/repositories/profile_settings_repository.dart';
import '../features/profile/repositories/public_profile_repository.dart';
import '../features/profile/repositories/user_search_repository.dart';
import '../features/push/repositories/push_repository.dart';
import '../features/ratings/repositories/rating_repository.dart';
import '../l10n/app_localizations.dart';
import 'navigation/auth_gate.dart';
import 'theme/app_theme.dart';

class APropApp extends StatelessWidget {
  const APropApp({
    super.key,
    required this.authRepository,
    this.activityRepository,
    this.activityClock = DateTime.now,
    this.activityMapRepository,
    this.enrollmentRepository,
    this.assistantRepository,
    this.ratingRepository,
    this.notificationRepository,
    this.discoveryRepository,
    this.profileRepository,
    this.profileSettingsRepository,
    this.publicProfileRepository,
    this.friendshipRepository,
    this.userSearchRepository,
    this.friendsRepository,
    this.attendanceRepository,
    this.pushMessaging,
    this.pushDeviceRepository,
    this.interestTestRepository,
    this.interestTestOnboardingMemory,
    this.activityCategoryRepository,
    this.userLocationRepository,
    this.activityChatRepository,
    this.localeController,
  });

  /// Drives the UI language. Without one the app stays in Catalan.
  final LocaleController? localeController;

  final AuthRepository authRepository;

  /// On és la persona, per al mapa d'Inici. Sense, el mapa no la mostra.
  final UserLocationRepository? userLocationRepository;

  /// Xat de les activitats. Sense, se'n fa servir un de demostració.
  final ActivityChatRepository? activityChatRepository;
  final ActivityRepository? activityRepository;
  final DateTime Function() activityClock;
  final ActivityMapRepository? activityMapRepository;
  final EnrollmentRepository? enrollmentRepository;
  final AssistantRepository? assistantRepository;
  final RatingRepository? ratingRepository;
  final NotificationRepository? notificationRepository;
  final DiscoveryRepository? discoveryRepository;
  final ProfileRepository? profileRepository;
  final ProfileSettingsRepository? profileSettingsRepository;
  final PublicProfileRepository? publicProfileRepository;
  final FriendshipRepository? friendshipRepository;
  final UserSearchRepository? userSearchRepository;
  final FriendsRepository? friendsRepository;
  final AttendanceRepository? attendanceRepository;

  /// Notificacions push (#265); només amb Firebase i backend.
  final PushMessaging? pushMessaging;
  final PushDeviceRepository? pushDeviceRepository;
  final InterestTestRepository? interestTestRepository;
  final InterestTestOnboardingMemory? interestTestOnboardingMemory;

  /// Categories per crear activitats. Si no hi és, el formulari fa servir la
  /// llista provisional.
  final ActivityCategoryRepository? activityCategoryRepository;

  @override
  Widget build(BuildContext context) {
    final authGate = AuthGate(
      key: ValueKey((
        authRepository,
        activityRepository,
        activityClock,
        activityMapRepository,
        enrollmentRepository,
        assistantRepository,
        ratingRepository,
        notificationRepository,
        discoveryRepository,
        profileRepository,
        profileSettingsRepository,
        publicProfileRepository,
        friendshipRepository,
        userSearchRepository,
        friendsRepository,
        attendanceRepository,
        pushMessaging,
        pushDeviceRepository,
        interestTestRepository,
        interestTestOnboardingMemory,
        activityCategoryRepository,
        userLocationRepository,
        activityChatRepository,
        localeController,
      )),
      authRepository: authRepository,
      localeController: localeController,
      activityRepository: activityRepository,
      activityClock: activityClock,
      activityMapRepository: activityMapRepository,
      enrollmentRepository: enrollmentRepository,
      assistantRepository: assistantRepository,
      ratingRepository: ratingRepository,
      notificationRepository: notificationRepository,
      discoveryRepository: discoveryRepository,
      profileRepository: profileRepository,
      profileSettingsRepository: profileSettingsRepository,
      publicProfileRepository: publicProfileRepository,
      friendshipRepository: friendshipRepository,
      userSearchRepository: userSearchRepository,
      friendsRepository: friendsRepository,
      attendanceRepository: attendanceRepository,
      pushMessaging: pushMessaging,
      pushDeviceRepository: pushDeviceRepository,
      interestTestRepository: interestTestRepository,
      interestTestOnboardingMemory: interestTestOnboardingMemory,
      activityCategoryRepository: activityCategoryRepository,
      userLocationRepository: userLocationRepository,
      activityChatRepository: activityChatRepository,
    );

    final controller = localeController;
    Widget app(Locale locale) => MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: controller == null
          ? null
          : (context, child) =>
                LocaleScope(controller: controller, child: child!),
      home: controller != null && controller.needsInitialSelection
          ? LanguageSelectionScreen(controller: controller)
          : authGate,
    );
    if (controller == null) return app(LocaleController.defaultLocale);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => app(controller.locale),
    );
  }
}
