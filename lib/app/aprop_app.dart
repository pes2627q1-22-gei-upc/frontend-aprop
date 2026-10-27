import 'package:flutter/material.dart';

import '../features/activities/repositories/activity_map_repository.dart';
import '../features/activities/repositories/activity_repository.dart';
import '../features/activities/repositories/discovery_repository.dart';
import '../features/activities/repositories/enrollment_repository.dart';
import '../features/assistant/repositories/assistant_repository.dart';
import '../features/auth/models/email_action.dart';
import '../features/auth/presentation/screens/email_action_screen.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../features/notifications/repositories/notification_repository.dart';
import '../features/profile/repositories/profile_repository.dart';
import '../features/profile/repositories/profile_settings_repository.dart';
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
    this.notificationRepository,
    this.discoveryRepository,
    this.profileRepository,
    this.profileSettingsRepository,
    this.emailAction,
  });

  final AuthRepository authRepository;
  final ActivityRepository? activityRepository;
  final ActivityMapRepository? activityMapRepository;
  final EnrollmentRepository? enrollmentRepository;
  final AssistantRepository? assistantRepository;
  final NotificationRepository? notificationRepository;
  final DiscoveryRepository? discoveryRepository;
  final ProfileRepository? profileRepository;
  final ProfileSettingsRepository? profileSettingsRepository;

  /// Acció d'un enllaç dels correus amb què s'ha obert la web (DP-031). Si n'hi
  /// ha, primer es mostra [EmailActionScreen].
  final EmailAction? emailAction;

  @override
  Widget build(BuildContext context) {
    final authGate = AuthGate(
      key: ValueKey((
        authRepository,
        activityRepository,
        activityMapRepository,
        enrollmentRepository,
        assistantRepository,
        notificationRepository,
        discoveryRepository,
        profileRepository,
        profileSettingsRepository,
      )),
      authRepository: authRepository,
      activityRepository: activityRepository,
      activityMapRepository: activityMapRepository,
      enrollmentRepository: enrollmentRepository,
      assistantRepository: assistantRepository,
      notificationRepository: notificationRepository,
      discoveryRepository: discoveryRepository,
      profileRepository: profileRepository,
      profileSettingsRepository: profileSettingsRepository,
    );

    return MaterialApp(
      title: 'AProp!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: switch (emailAction) {
        final action? => _EmailActionHome(
          repository: authRepository,
          action: action,
          app: authGate,
        ),
        null => authGate,
      },
    );
  }
}

/// Mostra la pàgina de l'enllaç del correu fins que l'usuari continua a l'app.
class _EmailActionHome extends StatefulWidget {
  const _EmailActionHome({
    required this.repository,
    required this.action,
    required this.app,
  });

  final AuthRepository repository;
  final EmailAction action;
  final Widget app;

  @override
  State<_EmailActionHome> createState() => _EmailActionHomeState();
}

class _EmailActionHomeState extends State<_EmailActionHome> {
  bool _continued = false;

  @override
  Widget build(BuildContext context) {
    if (_continued) return widget.app;
    return EmailActionScreen(
      repository: widget.repository,
      action: widget.action,
      onContinue: () => setState(() => _continued = true),
    );
  }
}
