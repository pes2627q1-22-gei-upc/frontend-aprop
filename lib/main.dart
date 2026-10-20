import 'package:flutter/material.dart';

import 'app/aprop_app.dart';
import 'features/auth/data/demo_auth_repository.dart';

void main() {
  // Comptes de demostració fins que configurem Firebase i l'alta al backend.
  runApp(APropApp(authRepository: DemoAuthRepository()));
}
