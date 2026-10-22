import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/aprop_app.dart';
import 'features/auth/data/demo_auth_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/repositories/auth_repository.dart';
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
  return FirebaseAuthRepository();
}
