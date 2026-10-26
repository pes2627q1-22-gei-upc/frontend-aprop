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
  final authRepository = await _createAuthRepository();

  // `X-User-ID` porta l'UUID de l'usuari a la base de dades del backend, el que
  // retorna `POST /auth/sync`. Sense sessió o sense backend, no s'envia.
  // TODO(DP-036): sobrarà quan el backend tregui l'usuari del token.
  String? serverUserId;
  authRepository.authStateChanges().listen((user) {
    serverUserId = user?.serverId;
  });

  if (!ApiConfig.isConfigured) {
    return APropApp(authRepository: authRepository);
  }

  final apiClient = ApiClient(
    baseUrl: Uri.parse(ApiConfig.baseUrl),
    idToken: authRepository.currentIdToken,
    userId: () => serverUserId,
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
          userId: () => auth.currentUser?.uid,
        )
      : DemoUserSyncRepository(
          currentUid: () => auth.currentUser?.uid,
          currentEmail: () => auth.currentUser?.email,
        );

  return FirebaseAuthRepository(auth: auth, userSync: userSync);
}
