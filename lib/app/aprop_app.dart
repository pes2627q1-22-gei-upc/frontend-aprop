import 'package:flutter/material.dart';

import '../features/auth/repositories/auth_repository.dart';
import '../features/activities/repositories/activity_repository.dart';
import '../features/activities/repositories/enrollment_repository.dart';
import 'navigation/auth_gate.dart';
import 'theme/app_theme.dart';

class APropApp extends StatelessWidget {
  const APropApp({
    super.key,
    required this.authRepository,
    this.activityRepository,
    this.enrollmentRepository,
  });

  final AuthRepository authRepository;
  final ActivityRepository? activityRepository;
  final EnrollmentRepository? enrollmentRepository;

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
          enrollmentRepository,
        )),
        authRepository: authRepository,
        activityRepository: activityRepository,
        enrollmentRepository: enrollmentRepository,
      ),
    );
  }
}
