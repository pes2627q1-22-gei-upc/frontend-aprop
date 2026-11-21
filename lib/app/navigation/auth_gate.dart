import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/activities/data/combined_activity_repository.dart';
import '../../features/activities/data/demo_activity_repository.dart';
import '../../features/activities/data/demo_discovery_repository.dart';
import '../../features/activities/data/demo_enrollment_repository.dart';
import '../../features/activities/repositories/activity_category_repository.dart';
import '../../features/activities/repositories/activity_map_repository.dart';
import '../../features/activities/repositories/activity_repository.dart';
import '../../features/activities/repositories/discovery_repository.dart';
import '../../features/activities/repositories/enrollment_repository.dart';
import '../../features/activities/repositories/user_location_repository.dart';
import '../../features/activity_chat/repositories/activity_chat_repository.dart';
import '../../features/assistant/data/demo_assistant_repository.dart';
import '../../features/assistant/repositories/assistant_repository.dart';
import '../../features/auth/models/app_user.dart';
import '../../features/auth/presentation/screens/choose_username_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/interest_test/data/demo_interest_test_repository.dart';
import '../../features/interest_test/presentation/screens/interest_test_screen.dart';
import '../../features/interest_test/repositories/interest_test_repository.dart';
import '../../features/notifications/data/demo_notification_repository.dart';
import '../../features/notifications/repositories/notification_repository.dart';
import '../../features/profile/data/demo_profile_repository.dart';
import '../../features/profile/data/demo_friendship_repository.dart';
import '../../features/profile/data/demo_profile_settings_repository.dart';
import '../../features/profile/data/demo_public_profile_repository.dart';
import '../../features/profile/data/demo_friends_repository.dart';
import '../../features/profile/data/demo_user_search_repository.dart';
import '../../features/profile/repositories/profile_repository.dart';
import '../../features/profile/repositories/profile_settings_repository.dart';
import '../../features/profile/repositories/public_profile_repository.dart';
import '../../features/profile/repositories/friendship_repository.dart';
import '../../features/attendance/data/demo_attendance_repository.dart';
import '../../features/attendance/repositories/attendance_repository.dart';
import '../../features/profile/repositories/friends_repository.dart';
import '../../features/profile/repositories/user_search_repository.dart';
import '../../features/ratings/data/demo_rating_repository.dart';
import '../../features/ratings/repositories/rating_repository.dart';
import 'main_shell.dart';

/// Mostra el login si no hi ha sessió, la verificació del correu si encara no
/// està verificat, la tria del nom d'usuari si encara no en té (primer accés
/// amb Google) i, si tot és correcte, l'aplicació.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authRepository,
    this.activityRepository,
    this.enrollmentRepository,
    this.assistantRepository,
    this.ratingRepository,
    this.notificationRepository,
    this.discoveryRepository,
    this.activityMapRepository,
    this.profileRepository,
    this.profileSettingsRepository,
    this.publicProfileRepository,
    this.friendshipRepository,
    this.userSearchRepository,
    this.friendsRepository,
    this.attendanceRepository,
    this.interestTestRepository,
    this.activityCategoryRepository,
    this.userLocationRepository,
    this.activityChatRepository,
  });

  final AuthRepository authRepository;

  /// On és la persona, per al mapa d'Inici. Sense, el mapa no la mostra.
  final UserLocationRepository? userLocationRepository;

  /// Xat de les activitats. Sense, MainShell en fa servir un de demostració.
  final ActivityChatRepository? activityChatRepository;
  final ActivityRepository? activityRepository;
  final EnrollmentRepository? enrollmentRepository;
  final AssistantRepository? assistantRepository;
  final RatingRepository? ratingRepository;
  final NotificationRepository? notificationRepository;
  final DiscoveryRepository? discoveryRepository;
  final ProfileRepository? profileRepository;
  final ProfileSettingsRepository? profileSettingsRepository;
  final PublicProfileRepository? publicProfileRepository;
  final FriendshipRepository? friendshipRepository;
  final UserSearchRepository? userSearchRepository;
  final FriendsRepository? friendsRepository;
  final AttendanceRepository? attendanceRepository;
  final InterestTestRepository? interestTestRepository;
  final ActivityCategoryRepository? activityCategoryRepository;

  /// Repositori opcional per al mapa d'Inici. Si és nul, el mapa mostra les
  /// activitats del catàleg d'`activityRepository`.
  final ActivityMapRepository? activityMapRepository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final ActivityRepository _activityRepository;
  late final EnrollmentRepository _enrollmentRepository;
  late final AssistantRepository _assistantRepository;
  late final RatingRepository _ratingRepository;
  late final NotificationRepository _notificationRepository;
  late final DiscoveryRepository _discoveryRepository;
  late final ActivityMapRepository? _activityMapRepository;
  late final ProfileRepository _profileRepository;
  late final ProfileSettingsRepository _profileSettingsRepository;
  late final PublicProfileRepository _publicProfileRepository;
  late final UserSearchRepository _userSearchRepository;
  late final FriendsRepository _friendsRepository;
  late final AttendanceRepository _attendanceRepository;
  late final InterestTestRepository _interestTestRepository;
  DemoEnrollmentRepository? _ownedEnrollmentRepository;
  DemoFriendshipRepository? _ownedFriendshipRepository;
  late final FriendshipRepository _friendshipRepository;
  String? _activeUserId;

  // Users whose onboarding interest test was already completed, skipped or
  // bypassed during this app run.
  // TODO(DP-066): Keep the skip decision in memory only for this run; decide
  // whether skipping should persist across restarts.
  final Set<String> _onboardingHandledUsers = {};

  @override
  void initState() {
    super.initState();
    _activityMapRepository = widget.activityMapRepository;

    final catalogue = widget.activityRepository ?? DemoActivityRepository();
    // Amb backend, les activitats obertes des del mapa també s'han de trobar
    // en apuntar-s'hi i a l'Agenda.
    _activityRepository = switch (_activityMapRepository) {
      final backend? when widget.activityRepository == null =>
        CombinedActivityRepository(catalogue: catalogue, backend: backend),
      _ => catalogue,
    };

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
    _ratingRepository = widget.ratingRepository ?? DemoRatingRepository();
    _friendshipRepository =
        widget.friendshipRepository ??
        (_ownedFriendshipRepository = DemoFriendshipRepository());
    _notificationRepository =
        widget.notificationRepository ??
        DemoNotificationRepository(
          activityRepository: _activityRepository,
          friendshipRepository: _friendshipRepository,
        );
    _discoveryRepository =
        widget.discoveryRepository ??
        DemoDiscoveryRepository(activityRepository: _activityRepository);
    _profileRepository =
        widget.profileRepository ??
        DemoProfileRepository(
          friendshipRepository: _ownedFriendshipRepository,
          activityRepository: _activityRepository,
          ratingRepository: switch (_ratingRepository) {
            final DemoRatingRepository demo => demo,
            _ => null,
          },
        );
    _profileSettingsRepository =
        widget.profileSettingsRepository ?? DemoProfileSettingsRepository();
    _publicProfileRepository =
        widget.publicProfileRepository ??
        DemoPublicProfileRepository(
          activityRepository: _activityRepository,
          friendshipRepository: _ownedFriendshipRepository,
          currentUserId: () => _activeUserId,
        );
    _userSearchRepository =
        widget.userSearchRepository ?? const DemoUserSearchRepository();
    _friendsRepository = widget.friendsRepository ?? DemoFriendsRepository();
    // One for the whole run, so answers survive signing out and in again.
    _attendanceRepository =
        widget.attendanceRepository ?? DemoAttendanceRepository();
    _interestTestRepository =
        widget.interestTestRepository ??
        DemoInterestTestRepository(activityRepository: _activityRepository);
  }

  @override
  void dispose() {
    unawaited(_ownedEnrollmentRepository?.dispose());
    unawaited(_ownedFriendshipRepository?.dispose());
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
        _activeUserId = user?.id;

        if (user == null) {
          return LoginScreen(repository: widget.authRepository);
        }

        if (!user.emailVerified) {
          return VerifyEmailScreen(
            repository: widget.authRepository,
            email: user.email,
          );
        }

        if (user.username == null) {
          return ChooseUsernameScreen(
            repository: widget.authRepository,
            firstName: user.firstName,
            rejectedUsername: user.rejectedUsername,
          );
        }

        if (!_onboardingHandledUsers.contains(user.id)) {
          return _InterestTestOnboardingGate(
            key: ValueKey(user.id),
            repository: _interestTestRepository,
            onDone: () => setState(() {
              _onboardingHandledUsers.add(user.id);
            }),
          );
        }

        return MainShell(
          // Si l'identificador del backend arriba més tard (sense connexió en
          // obrir l'app), les inscripcions s'han de tornar a carregar amb ell.
          key: ValueKey((user.id, user.serverId)),
          user: user,
          onSignOut: widget.authRepository.signOut,
          onDeleteAccount: widget.authRepository.deleteAccount,
          activityRepository: _activityRepository,
          enrollmentRepository: _enrollmentRepository,
          assistantRepository: _assistantRepository,
          ratingRepository: _ratingRepository,
          notificationRepository: _notificationRepository,
          discoveryRepository: _discoveryRepository,
          activityMapRepository: _activityMapRepository,
          profileRepository: _profileRepository,
          profileSettingsRepository: _profileSettingsRepository,
          publicProfileRepository: _publicProfileRepository,
          friendshipRepository: _friendshipRepository,
          userSearchRepository: _userSearchRepository,
          friendsRepository: _friendsRepository,
          attendanceRepository: _attendanceRepository,
          interestTestRepository: _interestTestRepository,
          activityCategoryRepository: widget.activityCategoryRepository,
          userLocationRepository: widget.userLocationRepository,
          activityChatRepository: widget.activityChatRepository,
        );
      },
    );
  }
}

/// Checks once whether the signed-in user has completed the interest test.
/// Shows [InterestTestScreen] (skippable via «Ara no») if not completed; on
/// completion, skip, or any status error it calls [onDone] so the app is never
/// blocked.
class _InterestTestOnboardingGate extends StatefulWidget {
  const _InterestTestOnboardingGate({
    super.key,
    required this.repository,
    required this.onDone,
  });

  final InterestTestRepository repository;
  final VoidCallback onDone;

  @override
  State<_InterestTestOnboardingGate> createState() =>
      _InterestTestOnboardingGateState();
}

class _InterestTestOnboardingGateState
    extends State<_InterestTestOnboardingGate> {
  bool _showTest = false;
  int _checkGeneration = 0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void didUpdateWidget(covariant _InterestTestOnboardingGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository && !_showTest) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final generation = ++_checkGeneration;
    try {
      final completed = await widget.repository.hasCompletedTest().timeout(
        const Duration(seconds: 3),
      );
      if (!mounted || generation != _checkGeneration) return;
      if (completed) {
        widget.onDone();
      } else {
        setState(() => _showTest = true);
      }
    } catch (_) {
      // Never block entry into the app when the status check fails.
      if (!mounted || generation != _checkGeneration) return;
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showTest) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return InterestTestScreen(
      repository: widget.repository,
      onSkip: widget.onDone,
      onDone: widget.onDone,
    );
  }
}
