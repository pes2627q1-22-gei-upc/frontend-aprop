import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/activities/data/demo_activity_repository.dart';
import '../../features/activities/data/demo_discovery_repository.dart';
import '../../features/activities/data/demo_enrollment_repository.dart';
import '../../features/activities/repositories/activity_repository.dart';
import '../../features/activities/repositories/discovery_repository.dart';
import '../../features/activities/repositories/enrollment_repository.dart';
import '../../features/assistant/data/demo_assistant_repository.dart';
import '../../features/assistant/repositories/assistant_repository.dart';
import '../../features/auth/models/app_user.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/notifications/data/demo_notification_repository.dart';
import '../../features/notifications/repositories/notification_repository.dart';
import '../../features/profile/data/demo_profile_repository.dart';
import '../../features/profile/data/demo_profile_settings_repository.dart';
import '../../features/profile/repositories/profile_repository.dart';
import '../../features/profile/repositories/profile_settings_repository.dart';
import 'main_shell.dart';

/// Mostra el login si no hi ha sessió, la verificació del correu si encara no
/// està verificat i, si tot és correcte, l'aplicació.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authRepository,
    this.activityRepository,
    this.enrollmentRepository,
    this.assistantRepository,
    this.notificationRepository,
    this.discoveryRepository,
    this.profileRepository,
    this.profileSettingsRepository,
  });

  final AuthRepository authRepository;
  final ActivityRepository? activityRepository;
  final EnrollmentRepository? enrollmentRepository;
  final AssistantRepository? assistantRepository;
  final NotificationRepository? notificationRepository;
  final DiscoveryRepository? discoveryRepository;
  final ProfileRepository? profileRepository;
  final ProfileSettingsRepository? profileSettingsRepository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final ActivityRepository _activityRepository;
  late final EnrollmentRepository _enrollmentRepository;
  late final AssistantRepository _assistantRepository;
  late final NotificationRepository _notificationRepository;
  late final DiscoveryRepository _discoveryRepository;
  late final ProfileRepository _profileRepository;
  late final ProfileSettingsRepository _profileSettingsRepository;
  DemoEnrollmentRepository? _ownedEnrollmentRepository;

  @override
  void initState() {
    super.initState();
    _activityRepository = widget.activityRepository ?? DemoActivityRepository();
    final suppliedRepository = widget.enrollmentRepository;
    if (suppliedRepository != null) {
      _enrollmentRepository = suppliedRepository;
    } else {
      _ownedEnrollmentRepository = DemoEnrollmentRepository(
        activityRepository: _activityRepository,
      );
      _enrollmentRepository = _ownedEnrollmentRepository!;
    }
    _assistantRepository =
        widget.assistantRepository ??
        DemoAssistantRepository(activityRepository: _activityRepository);
    _notificationRepository =
        widget.notificationRepository ??
        DemoNotificationRepository(activityRepository: _activityRepository);
    _discoveryRepository =
        widget.discoveryRepository ??
        DemoDiscoveryRepository(activityRepository: _activityRepository);
    _profileRepository =
        widget.profileRepository ??
        DemoProfileRepository(activityRepository: _activityRepository);
    _profileSettingsRepository =
        widget.profileSettingsRepository ?? DemoProfileSettingsRepository();
  }

  @override
  void dispose() {
    unawaited(_ownedEnrollmentRepository?.dispose());
    super.dispose();
  }

  // Es crea un sol cop: si es creés a build, cada redibuix tornaria a subscriure's.
  late final Stream<AppUser?> _authState = widget.authRepository
      .authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return LoginScreen(repository: widget.authRepository);
        }

        if (!user.emailVerified) {
          return VerifyEmailScreen(
            repository: widget.authRepository,
            email: user.email,
          );
        }

        return MainShell(
          key: ValueKey(user.id),
          user: user,
          onSignOut: widget.authRepository.signOut,
          activityRepository: _activityRepository,
          enrollmentRepository: _enrollmentRepository,
          assistantRepository: _assistantRepository,
          notificationRepository: _notificationRepository,
          discoveryRepository: _discoveryRepository,
          profileRepository: _profileRepository,
          profileSettingsRepository: _profileSettingsRepository,
        );
      },
    );
  }
}
