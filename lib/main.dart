import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/aprop_app.dart';
import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'features/activities/data/http_activity_map_repository.dart';
import 'features/activities/data/http_activity_repository.dart';
import 'features/activities/data/http_discovery_repository.dart';
import 'features/activities/data/http_enrollment_repository.dart';
import 'features/assistant/data/http_assistant_repository.dart';
import 'features/auth/data/demo_auth_repository.dart';
import 'features/auth/data/demo_user_sync_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/data/http_user_sync_repository.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/repositories/user_sync_repository.dart';
import 'features/notifications/data/http_notification_repository.dart';
import 'features/profile/data/http_profile_repository.dart';
import 'features/profile/data/http_profile_settings_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await createConfiguredApp());
}

/// Construeix l'[APropApp] injectant els repositoris HTTP connectats a Render
/// quan [ApiConfig.isConfigured] és cert, o els de demostració altrament.
Future<APropApp> createConfiguredApp() async {
  String? currentUserId;
  final authRepository = await _createAuthRepository(
    onUserIdResolved: (getter) => currentUserId = getter(),
  );

  // Manté l'ID d'usuari sincronitzat amb els canvis de sessió per a `X-User-ID`.
  authRepository.authStateChanges().listen((user) {
    currentUserId = user?.id;
  });

  if (!ApiConfig.isConfigured) {
    return APropApp(authRepository: authRepository);
  }

  final apiClient = ApiClient(
    baseUrl: Uri.parse(ApiConfig.baseUrl),
    idToken: authRepository.currentIdToken,
    userId: () => currentUserId == null
        ? null
        : ApiClient.toCanonicalUuid(currentUserId!),
  );

  final activityRepository = HttpActivityRepository(apiClient: apiClient);

  return APropApp(
    authRepository: authRepository,
    activityRepository: activityRepository,
    activityMapRepository: HttpActivityMapRepository(apiClient: apiClient),
    enrollmentRepository: HttpEnrollmentRepository(apiClient: apiClient),
    discoveryRepository: HttpDiscoveryRepository(
      apiClient: apiClient,
      activityRepository: activityRepository,
    ),
    assistantRepository: HttpAssistantRepository(apiClient: apiClient),
    notificationRepository: HttpNotificationRepository(
      apiClient: apiClient,
      activityRepository: activityRepository,
    ),
    profileRepository: HttpProfileRepository(apiClient: apiClient),
    profileSettingsRepository: HttpProfileSettingsRepository(
      apiClient: apiClient,
    ),
  );
}

/// Firebase està configurat per a Android i per a la web (que només fem servir
/// per desenvolupar). A iOS es continuen fent servir els comptes de
/// demostració.
// TODO(DP-026): configurar iOS quan hi hagi qui ho pugui provar.
Future<AuthRepository> _createAuthRepository({
  required void Function(String? Function() getter) onUserIdResolved,
}) async {
  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
    onUserIdResolved(() => null);
    return DemoAuthRepository();
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final auth = FirebaseAuth.instance;
  onUserIdResolved(() => auth.currentUser?.uid);

  final UserSyncRepository userSync = ApiConfig.isConfigured
      ? HttpUserSyncRepository(
          baseUrl: Uri.parse(ApiConfig.baseUrl),
          idToken: () async => auth.currentUser?.getIdToken(),
          userId: () => auth.currentUser?.uid,
        )
      : DemoUserSyncRepository(
          currentUid: () => auth.currentUser?.uid,
          currentEmail: () => auth.currentUser?.email,
        );

  return FirebaseAuthRepository(auth: auth, userSync: userSync);
}
