import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/locale_controller.dart';
import '../l10n/app_localizations.dart';
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
import '../features/profile/repositories/public_profile_repository.dart';
import '../features/profile/repositories/friendship_repository.dart';
import '../features/profile/repositories/user_search_repository.dart';
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
    this.publicProfileRepository,
    this.friendshipRepository,
    this.userSearchRepository,
    this.interestTestRepository,
    this.activityCategoryRepository,
    this.userLocationRepository,
    this.localeController,
  });

  /// Drives the UI language. Without one the app stays in Catalan.
  final LocaleController? localeController;

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
  final PublicProfileRepository? publicProfileRepository;
  final FriendshipRepository? friendshipRepository;
  final UserSearchRepository? userSearchRepository;
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
        publicProfileRepository,
        friendshipRepository,
        userSearchRepository,
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
      publicProfileRepository: publicProfileRepository,
      friendshipRepository: friendshipRepository,
      userSearchRepository: userSearchRepository,
      interestTestRepository: interestTestRepository,
      activityCategoryRepository: activityCategoryRepository,
      userLocationRepository: userLocationRepository,
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
      home: authGate,
    );
    if (controller == null) return app(LocaleController.defaultLocale);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => app(controller.locale),
    );
  }
}
