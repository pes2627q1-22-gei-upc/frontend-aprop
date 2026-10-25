import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/aprop_app.dart';
import 'core/config/api_config.dart';
import 'features/auth/data/demo_auth_repository.dart';
import 'features/auth/data/demo_user_sync_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/data/http_user_sync_repository.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/repositories/user_sync_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(APropApp(authRepository: await _createAuthRepository()));
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

  // Sense URL del backend, el nom d'usuari es desa al dispositiu (DP-028).
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
