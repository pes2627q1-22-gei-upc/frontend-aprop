import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/locale_controller.dart';
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
import '../../features/interest_test/repositories/interest_test_onboarding_memory.dart';
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
    this.interestTestOnboardingMemory,
    this.activityCategoryRepository,
    this.userLocationRepository,
    this.activityChatRepository,
    this.localeController,
  });

  final AuthRepository authRepository;
  final LocaleController? localeController;

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
  final InterestTestOnboardingMemory? interestTestOnboardingMemory;
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
  late final InterestTestOnboardingMemory _interestTestOnboardingMemory;
  DemoEnrollmentRepository? _ownedEnrollmentRepository;
  DemoFriendshipRepository? _ownedFriendshipRepository;
  late final FriendshipRepository _friendshipRepository;
  String? _activeUserId;
  String? _languageSyncedUserId;

  // Users whose onboarding interest test was already completed, skipped or
  // bypassed during this app run (fast-path before querying persistent memory
  // and server-side Users.InterestTestPrompted; TODO(DP-078)).
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
    _friendsRepository =
        widget.friendsRepository ??
        DemoFriendsRepository(
          friendshipRepository: _ownedFriendshipRepository,
          currentUserId: () => _activeUserId,
        );
    // One for the whole run, so answers survive signing out and in again.
    _attendanceRepository =
        widget.attendanceRepository ?? DemoAttendanceRepository();
    _interestTestRepository =
        widget.interestTestRepository ??
        DemoInterestTestRepository(activityRepository: _activityRepository);
    _interestTestOnboardingMemory =
        widget.interestTestOnboardingMemory ??
        InMemoryInterestTestOnboardingMemory();
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
          _languageSyncedUserId = null;
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

        final localeController =
            widget.localeController ?? LocaleScope.maybeOf(context);
        if (localeController != null && _languageSyncedUserId != user.id) {
          return _LanguageSyncGate(
            key: ValueKey(('lang-sync', user.id)),
            userId: user.id,
            repository: _profileSettingsRepository,
            localeController: localeController,
            onDone: () => setState(() {
              _languageSyncedUserId = user.id;
            }),
          );
        }

        if (!_onboardingHandledUsers.contains(user.id)) {
          return _InterestTestOnboardingGate(
            key: ValueKey(user.id),
            userId: user.id,
            repository: _interestTestRepository,
            onboardingMemory: _interestTestOnboardingMemory,
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

/// Checks once whether a newly registered account should see the onboarding
/// interest test. Shows [InterestTestScreen] (pausable via «Més tard») only
/// when the account has never been prompted, started, or completed; immediately
/// marks onboarding as prompted (server-side + local fallback) so skipping or
/// closing the app never forces it again on later logins.
class _InterestTestOnboardingGate extends StatefulWidget {
  const _InterestTestOnboardingGate({
    super.key,
    required this.userId,
    required this.repository,
    required this.onboardingMemory,
    required this.onDone,
  });

  final String userId;
  final InterestTestRepository repository;
  final InterestTestOnboardingMemory onboardingMemory;
  final VoidCallback onDone;

  @override
  State<_InterestTestOnboardingGate> createState() =>
      _InterestTestOnboardingGateState();
}

class _InterestTestOnboardingGateState
    extends State<_InterestTestOnboardingGate> {
  bool _showTest = false;
  int _initialAnsweredCount = 0;
  int _checkGeneration = 0;
  bool _promptMarked = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void didUpdateWidget(covariant _InterestTestOnboardingGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.repository != widget.repository ||
            oldWidget.userId != widget.userId) &&
        !_showTest) {
      _checkStatus();
    }
  }

  void _markPrompted() {
    if (_promptMarked) return;
    _promptMarked = true;
    unawaited(widget.onboardingMemory.markPrompted(widget.userId));
    unawaited(
      widget.repository.markOnboardingPrompted().catchError((Object _) {}),
    );
  }

  Future<void> _checkStatus() async {
    final generation = ++_checkGeneration;
    try {
      if (await widget.onboardingMemory.wasPrompted(widget.userId)) {
        if (!mounted || generation != _checkGeneration) return;
        widget.onDone();
        return;
      }

      final status = await widget.repository.getTestStatus().timeout(
        const Duration(seconds: 3),
      );
      if (!mounted || generation != _checkGeneration) return;
      if (!status.shouldPromptOnboarding) {
        unawaited(widget.onboardingMemory.markPrompted(widget.userId));
        widget.onDone();
      } else {
        // Mark as prompted as soon as onboarding is shown so even force-closing
        // the app counts and the test never reappears on later logins.
        _markPrompted();
        setState(() {
          _initialAnsweredCount = status.answeredCount;
          _showTest = true;
        });
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
      initialAnsweredCount: _initialAnsweredCount,
      onSkip: widget.onDone,
      onDone: widget.onDone,
    );
  }
}

/// Synchronizes the UI language with the signed-in user's profile once per
/// session before onboarding / [MainShell]: if the profile already has a
/// supported language, applies it locally; otherwise pushes the local one.
/// Failures never block entering the app.
class _LanguageSyncGate extends StatefulWidget {
  const _LanguageSyncGate({
    super.key,
    required this.userId,
    required this.repository,
    required this.localeController,
    required this.onDone,
  });

  final String userId;
  final ProfileSettingsRepository repository;
  final LocaleController localeController;
  final VoidCallback onDone;

  @override
  State<_LanguageSyncGate> createState() => _LanguageSyncGateState();
}

class _LanguageSyncGateState extends State<_LanguageSyncGate> {
  int _syncGeneration = 0;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _LanguageSyncGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.repository != widget.repository ||
        oldWidget.localeController != widget.localeController) {
      _sync();
    }
  }

  Future<void> _sync() async {
    final generation = ++_syncGeneration;
    try {
      final settings = await widget.repository
          .getSettings(widget.userId)
          .timeout(const Duration(seconds: 3));
      if (!mounted || generation != _syncGeneration) return;
      final profileLocale = LocaleController.supportedLocaleFor(
        settings.language,
      );
      if (profileLocale != null) {
        if (profileLocale != widget.localeController.locale) {
          await widget.localeController.setLocale(profileLocale);
        }
      } else {
        await widget.repository
            .updateLanguage(
              userId: widget.userId,
              language: widget.localeController.locale.languageCode,
            )
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {
      // Never block entry into the app when language sync fails.
    }
    if (!mounted || generation != _syncGeneration) return;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
