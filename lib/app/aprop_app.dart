import 'package:flutter/material.dart';

import '../features/auth/repositories/auth_repository.dart';
import '../features/activities/repositories/activity_repository.dart';
import '../features/activities/repositories/enrollment_repository.dart';
import '../features/assistant/repositories/assistant_repository.dart';
import 'navigation/auth_gate.dart';
import 'theme/app_theme.dart';

class APropApp extends StatelessWidget {
  const APropApp({
    super.key,
    required this.authRepository,
    this.activityRepository,
    this.enrollmentRepository,
    this.assistantRepository,
  });

  final AuthRepository authRepository;
  final ActivityRepository? activityRepository;
  final EnrollmentRepository? enrollmentRepository;
  final AssistantRepository? assistantRepository;

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
          assistantRepository,
        )),
        authRepository: authRepository,
        activityRepository: activityRepository,
        enrollmentRepository: enrollmentRepository,
        assistantRepository: assistantRepository,
      ),
    );
  }
}
