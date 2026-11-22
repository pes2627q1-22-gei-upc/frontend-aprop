import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/aprop_app.dart';
import 'core/config/api_config.dart';
import 'core/l10n/locale_controller.dart';
import 'core/network/api_client.dart';
import 'features/activities/data/geolocator_user_location_repository.dart';
import 'features/activities/data/http_activity_map_repository.dart';
import 'features/activities/data/http_activity_repository.dart';
import 'features/activities/data/http_discovery_repository.dart';
import 'features/activities/data/http_enrollment_repository.dart';
import 'features/activity_chat/data/http_activity_chat_repository.dart';
import 'features/assistant/data/http_assistant_repository.dart';
import 'features/attendance/data/http_attendance_repository.dart';
import 'features/attendance/data/remembered_attendance_repository.dart';
import 'features/attendance/data/shared_preferences_attendance_memory.dart';
import 'features/auth/data/demo_auth_repository.dart';
import 'features/auth/data/demo_user_sync_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/data/http_user_sync_repository.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/repositories/user_sync_repository.dart';
import 'features/interest_test/data/http_interest_test_repository.dart';
import 'features/interest_test/data/shared_preferences_interest_test_onboarding_memory.dart';
import 'features/notifications/data/http_notification_repository.dart';
import 'features/profile/data/http_friends_repository.dart';
import 'features/profile/data/http_friendship_repository.dart';
import 'features/profile/data/http_profile_repository.dart';
import 'features/profile/data/http_profile_settings_repository.dart';
import 'features/profile/data/http_public_profile_repository.dart';
import 'features/profile/data/http_user_search_repository.dart';
import 'features/ratings/data/http_rating_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await createConfiguredApp());
}

/// Construeix l'[APropApp] injectant els repositoris HTTP connectats a Render
/// quan [ApiConfig.isConfigured] és cert, o els de demostració altrament.
Future<APropApp> createConfiguredApp() async {
  final authRepository = await _createAuthRepository();
  // La ubicació no depèn del backend: també funciona amb les demostracions.
  const userLocationRepository = GeolocatorUserLocationRepository();
  final localeController = LocaleController();
  await localeController.load();
  // Existing installs have no stored language: don't ask a signed-in user.
  if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
    localeController.skipInitialSelection();
  }

  if (!ApiConfig.isConfigured) {
    return APropApp(
      authRepository: authRepository,
      userLocationRepository: userLocationRepository,
      localeController: localeController,
    );
  }

  final apiClient = ApiClient(
    baseUrl: Uri.parse(ApiConfig.baseUrl),
    idToken: authRepository.currentIdToken,
    language: () => localeController.locale.languageCode,
  );

  final activityRepository = HttpActivityRepository(apiClient: apiClient);
  final friendshipRepository = HttpFriendshipRepository(apiClient: apiClient);

  return APropApp(
    authRepository: authRepository,
    localeController: localeController,
    activityRepository: activityRepository,
    activityCategoryRepository: activityRepository,
    activityMapRepository: HttpActivityMapRepository(apiClient: apiClient),
    enrollmentRepository: HttpEnrollmentRepository(apiClient: apiClient),
    discoveryRepository: HttpDiscoveryRepository(apiClient: apiClient),
    assistantRepository: HttpAssistantRepository(apiClient: apiClient),
    friendshipRepository: friendshipRepository,
    notificationRepository: HttpNotificationRepository(
      friendshipRepository: friendshipRepository,
      apiClient: apiClient,
      activityRepository: activityRepository,
    ),
    profileRepository: HttpProfileRepository(apiClient: apiClient),
    publicProfileRepository: HttpPublicProfileRepository(apiClient: apiClient),
    userSearchRepository: HttpUserSearchRepository(apiClient: apiClient),
    friendsRepository: HttpFriendsRepository(apiClient: apiClient),
    // TODO(DP-068): the API cannot say «did not go»; the device remembers it.
    attendanceRepository: RememberedAttendanceRepository(
      inner: HttpAttendanceRepository(apiClient: apiClient),
      memory: const SharedPreferencesAttendanceMemory(),
    ),
    profileSettingsRepository: HttpProfileSettingsRepository(
      apiClient: apiClient,
    ),
    interestTestRepository: HttpInterestTestRepository(apiClient: apiClient),
    interestTestOnboardingMemory:
        const SharedPreferencesInterestTestOnboardingMemory(),
    userLocationRepository: userLocationRepository,
    ratingRepository: HttpRatingRepository(apiClient: apiClient),
    activityChatRepository: HttpActivityChatRepository(apiClient: apiClient),
  );
}

/// Firebase està configurat per a Android i per a la web (que només fem servir
/// per desenvolupar). A iOS es continuen fent servir els comptes de
/// demostració.
// TODO(DP-026): configurar iOS quan hi hagi qui ho pugui provar.
Future<AuthRepository> _createAuthRepository() async {
  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
    return DemoAuthRepository();
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final auth = FirebaseAuth.instance;

  final UserSyncRepository userSync = ApiConfig.isConfigured
      ? HttpUserSyncRepository(
          baseUrl: Uri.parse(ApiConfig.baseUrl),
          idToken: () async => auth.currentUser?.getIdToken(),
        )
      : DemoUserSyncRepository(
          currentUid: () => auth.currentUser?.uid,
          currentEmail: () => auth.currentUser?.email,
        );

  return FirebaseAuthRepository(auth: auth, userSync: userSync);
}
