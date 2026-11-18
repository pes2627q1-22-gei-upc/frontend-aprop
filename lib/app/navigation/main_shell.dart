import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/activities/data/demo_location_repository.dart';
import '../../features/activities/models/activity.dart';
import '../../features/activities/presentation/screens/activities_screen.dart';
import '../../features/activities/presentation/screens/activity_search_screen.dart';
import '../../features/activities/presentation/screens/create_activity_screen.dart';
import '../../features/activities/presentation/screens/discover_screen.dart';
import '../../features/activities/presentation/widgets/activities_map.dart';
import '../../features/activities/presentation/view_models/activities_map_view_model.dart';
import '../../features/activities/presentation/view_models/activities_view_model.dart';
import '../../features/activities/presentation/view_models/enrollment_view_model.dart';
import '../../features/activities/presentation/widgets/enrollment_action.dart';
import '../../features/activities/repositories/activity_category_repository.dart';
import '../../features/activities/repositories/activity_details_repository.dart';
import '../../features/activities/repositories/activity_map_repository.dart';
import '../../features/activities/repositories/activity_repository.dart';
import '../../features/activities/repositories/discovery_repository.dart';
import '../../features/activities/repositories/enrollment_repository.dart';
import '../../features/agenda/presentation/screens/agenda_screen.dart';
import '../../features/assistant/models/assistant_message.dart';
import '../../features/assistant/presentation/screens/assistant_screen.dart';
import '../../features/assistant/presentation/view_models/assistant_view_model.dart';
import '../../features/assistant/repositories/assistant_repository.dart';
import '../../features/auth/models/app_user.dart';
import '../../features/interest_test/presentation/screens/interest_test_screen.dart';
import '../../features/interest_test/repositories/interest_test_repository.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/repositories/notification_repository.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/profile_settings_screen.dart';
import '../../features/profile/presentation/view_models/profile_view_model.dart';
import '../../features/profile/data/gallery_profile_image_picker.dart';
import '../../features/profile/repositories/profile_repository.dart';
import '../../features/profile/repositories/profile_settings_repository.dart';
import '../../features/ratings/presentation/view_models/rating_view_model.dart';
import '../../features/ratings/presentation/widgets/activity_rating.dart';
import '../../features/ratings/repositories/rating_repository.dart';
import 'activity_details_route.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.activityRepository,
    required this.enrollmentRepository,
    required this.assistantRepository,
    required this.ratingRepository,
    required this.notificationRepository,
    required this.discoveryRepository,
    this.activityMapRepository,
    required this.profileRepository,
    required this.profileSettingsRepository,
    this.interestTestRepository,
    this.activityCategoryRepository,
    this.now,
  });

  final AppUser user;
  final Future<void> Function() onSignOut;
  final ActivityRepository activityRepository;
  final EnrollmentRepository enrollmentRepository;
  final AssistantRepository assistantRepository;
  final RatingRepository ratingRepository;
  final NotificationRepository notificationRepository;
  final DiscoveryRepository discoveryRepository;
  final ProfileRepository profileRepository;
  final ProfileSettingsRepository profileSettingsRepository;

  /// Si no hi és, «Tornar a fer el test d’interessos» queda pendent.
  final InterestTestRepository? interestTestRepository;

  /// Categories per crear activitats. Si no hi és, el formulari fa servir la
  /// llista provisional.
  final ActivityCategoryRepository? activityCategoryRepository;

  /// Si hi és, el mapa d'Inici carrega per zona des d'aquí. Si no, mostra les
  /// activitats de la llista.
  final ActivityMapRepository? activityMapRepository;

  /// Clock for the Agenda and for when an activity can be rated; tests inject it.
  final DateTime Function()? now;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _isAssistantOpen = false;

  /// Identificador de les inscripcions: el backend les desa amb l'UUID de
  /// l'usuari, no amb l'UID de Firebase. Apuntar-se i l'Agenda han de fer
  /// servir el mateix, perquè comparteixen les inscripcions.
  String get _enrollmentUserId => widget.user.serverId ?? widget.user.id;

  /// Quant ha de pujar el botó de l'assistent perquè no el tapi la targeta
  /// del mapa.
  final _assistantButtonLift = ValueNotifier<double>(0);

  /// Avisa que una activitat ha canviat (s'ha editat), perquè les pantalles
  /// que en guarden una còpia, com l'Agenda, la tornin a carregar.
  final _activitiesChanged = ValueNotifier<int>(0);
  final _sectionNavigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );
  late final ActivityRepository _activityRepository;
  late final ActivitiesViewModel _activitiesViewModel;
  ActivitiesMapViewModel? _activitiesMapViewModel;
  late final EnrollmentViewModel _enrollmentViewModel;
  late final RatingViewModel _ratingViewModel;
  late final AssistantViewModel _assistantViewModel;
  late final ProfileViewModel _profileViewModel;

  static const _titles = ['AProp!', 'Agenda', 'Descobreix', 'Avisos', 'Perfil'];

  @override
  void initState() {
    //flutter llama porque es la pantalla inicial de la app. Se crea el ViewModel y se carga la lista de actividades.
    super.initState();

    _activityRepository = widget.activityRepository;
    _activitiesViewModel = ActivitiesViewModel(repository: _activityRepository);
    if (widget.activityMapRepository case final mapRepository?) {
      _activitiesMapViewModel = ActivitiesMapViewModel(
        repository: mapRepository,
      );
    }
    _enrollmentViewModel = EnrollmentViewModel(
      userId: _enrollmentUserId,
      repository: widget.enrollmentRepository,
    );
    _ratingViewModel = RatingViewModel(
      userId: _enrollmentUserId,
      repository: widget.ratingRepository,
    );
    _assistantViewModel = AssistantViewModel(
      repository: widget.assistantRepository,
    );
    _profileViewModel = ProfileViewModel(
      user: widget.user,
      repository: widget.profileRepository,
      imagePicker: widget.profileRepository.capabilities.uploadAvatar
          ? GalleryProfileImagePicker()
          : null,
    )..load();
    _profileViewModel.checkInterruptedAvatarSelection();
    _enrollmentViewModel.load();

    _activitiesViewModel.load(); //mientras espera ésto flutter dibuja un indicador de carga. Cuando termina, el ViewModel notifica a la pantalla y ésta se redibuja con la lista de actividades.
  }

  @override
  void dispose() {
    _assistantButtonLift.dispose();
    _activitiesChanged.dispose();
    _activitiesViewModel.dispose();
    _activitiesMapViewModel?.dispose();
    _enrollmentViewModel.dispose();
    _ratingViewModel.dispose();
    _assistantViewModel.dispose();
    _profileViewModel.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;
    // Refresh ownership/history after changes made in another section.
    if (index == 4) _profileViewModel.load();

    setState(() {
      _selectedIndex = index;
    });
  }

  /// [repository] és la font de l'activitat si no és el catàleg (el mapa).
  void _openActivityDetails(
    String activityId, {
    ActivityDetailsRepository? repository,
  }) {
    final navigator = _sectionNavigatorKeys[_selectedIndex].currentState!;
    // The callback comes from a section root; ignore repeated taps in transit.
    if (navigator.canPop()) return;
    navigator.push<void>(
      activityDetailsRoute(
        activityId: activityId,
        repository: repository ?? _activityRepository,
        enrollmentViewModel: _enrollmentViewModel,
        ratingBuilder: _buildRating,
        canEdit: _canEdit,
        onEdit: _editActivity,
      ),
    );
  }

  /// Rating stars for plans the user joined and that already started.
  // TODO(DP-048): attendance («Com va anar?») is not modelled; once it is,
  // require a confirmed attendance instead of an enrollment.
  Widget _buildRating(Activity activity) {
    return ListenableBuilder(
      listenable: _enrollmentViewModel,
      builder: (context, child) {
        if (!_enrollmentViewModel.isEnrolled(activity.id) ||
            activity.startsAt.isAfter((widget.now ?? DateTime.now)())) {
          return const SizedBox.shrink();
        }
        return ActivityRating(
          viewModel: _ratingViewModel,
          activityId: activity.id,
        );
      },
    );
  }

  /// Leaves the assistant and shows the screen one of its replies suggested.
  void _openAssistantTarget(AssistantScreenTarget target) {
    _sectionNavigatorKeys[0].currentState!.popUntil((r) => r.isFirst);
    final index = switch (target) {
      AssistantScreenTarget.home => 0,
      AssistantScreenTarget.agenda => 1,
      AssistantScreenTarget.discover => 2,
      AssistantScreenTarget.notifications => 3,
      AssistantScreenTarget.profile ||
      AssistantScreenTarget.settings ||
      AssistantScreenTarget.interestTest => 4,
    };
    _selectDestination(index);
    if (target == AssistantScreenTarget.settings) {
      _sectionNavigatorKeys[4].currentState!.popUntil((r) => r.isFirst);
      _openProfileSettings();
    } else if (target == AssistantScreenTarget.interestTest) {
      _sectionNavigatorKeys[4].currentState!.popUntil((r) => r.isFirst);
      _openInterestTest();
    }
  }

  void _openInterestTest() {
    final repository = widget.interestTestRepository;
    final navigator = _sectionNavigatorKeys[4].currentState;
    if (repository == null || navigator == null) return;
    navigator.push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/profile/interest-test'),
        builder: (context) => InterestTestScreen(
          repository: repository,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _openAssistant() async {
    final navigator = _sectionNavigatorKeys[0].currentState!;
    if (_isAssistantOpen || navigator.canPop()) return;
    // TODO(DP-048): Confirm that details opened from chat keep this full-body
    // flow. The section's history and shared ViewModels remain mounted.
    setState(() => _isAssistantOpen = true);
    try {
      await navigator.push<void>(
        PageRouteBuilder<void>(
          settings: const RouteSettings(name: '/assistant'),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondary, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curve),
                child: child,
              ),
            );
          },
          pageBuilder: (context, animation, secondary) => AssistantScreen(
            viewModel: _assistantViewModel,
            onOpenScreen: _openAssistantTarget,
            onActivitySelected: (activityId) {
              if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
              Navigator.of(context).push<void>(
                activityDetailsRoute(
                  activityId: activityId,
                  repository: _activityRepository,
                  enrollmentViewModel: _enrollmentViewModel,
                  ratingBuilder: _buildRating,
                  canEdit: _canEdit,
                  onEdit: _editActivity,
                ),
              );
            },
            participationActionBuilder: (activity) => EnrollmentAction(
              viewModel: _enrollmentViewModel,
              activityId: activity.id,
              activityTitle: activity.title,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAssistantOpen = false);
    }
  }

  void _openDiscoverySearch() {
    final navigator = _sectionNavigatorKeys[2].currentState!;
    if (_selectedIndex != 2 || navigator.canPop()) return;
    navigator.push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/discover/search'),
        builder: (context) => ActivitySearchScreen(
          repository: widget.discoveryRepository,
          enrollmentViewModel: _enrollmentViewModel,
          onBack: () => Navigator.of(context).pop(),
          onActivitySelected: (activityId) {
            if (_selectedIndex != 2 ||
                !(ModalRoute.of(context)?.isCurrent ?? false)) {
              return;
            }
            Navigator.of(context).push<void>(
              activityDetailsRoute(
                activityId: activityId,
                repository: _activityRepository,
                enrollmentViewModel: _enrollmentViewModel,
                ratingBuilder: _buildRating,
                canEdit: _canEdit,
                onEdit: _editActivity,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Qui publica o edita una activitat des de l'app.
  ActivityCreator get _currentCreator => ActivityCreator(
    name: _profileViewModel.profile?.displayName ?? widget.user.fullName,
    userId: widget.user.id,
    isFriend: false,
  );

  void _openCreateActivity() {
    final navigator = _sectionNavigatorKeys[0].currentState!;
    if (navigator.canPop()) return;
    navigator.push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/activities/new'),
        builder: (context) => CreateActivityScreen(
          repository: _activityRepository,
          locationRepository: const DemoLocationRepository(),
          categoryRepository: widget.activityCategoryRepository,
          creator: _currentCreator,
          onCreated: (activity) => _showCreatedActivity(navigator, activity),
        ),
      ),
    );
  }

  /// Només qui ha creat una activitat no oficial la pot editar, i només
  /// abans que comenci (CA1 i CA2 de la #50).
  bool _canEdit(Activity activity) {
    final creatorId = activity.creator?.userId;
    return activity.source == ActivitySource.community &&
        creatorId != null &&
        (creatorId == widget.user.serverId || creatorId == widget.user.id) &&
        activity.startsAt.isAfter(DateTime.now());
  }

  /// Obre el formulari amb l'activitat i, si es desa, posa al dia la llista,
  /// el mapa i l'Agenda. La fitxa es torna a carregar sola.
  Future<bool> _editActivity(Activity activity) async {
    final navigator = _sectionNavigatorKeys[_selectedIndex].currentState!;
    final saved = await navigator.push<Activity>(
      MaterialPageRoute<Activity>(
        settings: RouteSettings(
          name: '/activities/${Uri.encodeComponent(activity.id)}/edit',
        ),
        builder: (context) => CreateActivityScreen(
          repository: _activityRepository,
          locationRepository: const DemoLocationRepository(),
          categoryRepository: widget.activityCategoryRepository,
          creator: _currentCreator,
          activity: activity,
          onCreated: (updated) => Navigator.of(context).pop(updated),
        ),
      ),
    );
    if (saved == null) return false;
    _activitiesMapViewModel?.refresh();
    _activitiesViewModel.load();
    _activitiesChanged.value++;
    return true;
  }

  void _openProfileSettings() {
    final navigator = _sectionNavigatorKeys[4].currentState!;
    if (_selectedIndex != 4 || navigator.canPop()) return;
    navigator.push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/profile/settings'),
        builder: (context) => ProfileSettingsScreen(
          user: widget.user,
          repository: widget.profileSettingsRepository,
          onSignOut: widget.onSignOut,
          onBack: () => Navigator.of(context).pop(),
          onOpenInterestTest: switch (widget.interestTestRepository) {
            final repository? => () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/profile/interest-test'),
                builder: (context) => InterestTestScreen(
                  repository: repository,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            null => null,
          },
        ),
      ),
    );
  }

  // TODO(DP-032): Share a real public link when a profile route is agreed.
  void _shareOwnProfile() {
    final username =
        _profileViewModel.profile?.username ?? widget.user.username;
    if (username == null || username.isEmpty) return;
    var copying = false;
    showDialog<void>(
      context: _sectionNavigatorKeys[4].currentState!.overlay!.context,
      useRootNavigator: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Compartir perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('@$username'),
              const SizedBox(height: 8),
              const Text('Comparteix el teu nom d’usuari d’AProp!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: copying
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel·lar'),
            ),
            FilledButton(
              onPressed: copying
                  ? null
                  : () async {
                      setDialogState(() => copying = true);
                      try {
                        await Clipboard.setData(
                          ClipboardData(text: '@$username'),
                        );
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Nom d’usuari copiat'),
                            ),
                          );
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          setDialogState(() => copying = false);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No hem pogut copiar el nom d’usuari.',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: Text(copying ? 'Copiant…' : 'Copiar nom d’usuari'),
            ),
          ],
        ),
      ),
    );
  }

  /// Qui crea una activitat hi queda apuntat. Després es veu la seva fitxa en
  /// lloc del formulari i, en tornar enrere, la llista ja la inclou.
  // TODO(DP-017): si el backend apunta la persona creadora en crear
  // l'activitat, aquesta crida a enroll sobrarà.
  void _showCreatedActivity(NavigatorState navigator, Activity activity) {
    _enrollmentViewModel.enroll(activity.id);
    // Perquè l'activitat nova surti al mapa sense haver-lo de moure.
    _activitiesMapViewModel?.refresh();
    _activitiesViewModel.load();
    navigator.pushReplacement<void, void>(
      activityDetailsRoute(
        activityId: activity.id,
        repository: _activityRepository,
        enrollmentViewModel: _enrollmentViewModel,
        ratingBuilder: _buildRating,
        canEdit: _canEdit,
        onEdit: _editActivity,
      ),
    );
  }

  Widget _buildSectionNavigator(int index, WidgetBuilder rootBuilder) {
    final key = _sectionNavigatorKeys[index];
    return TickerMode(
      enabled: _selectedIndex == index,
      child: NavigatorPopHandler<void>(
        enabled: _selectedIndex == index,
        onPopWithResult: (_) {
          if (_selectedIndex == index &&
              (key.currentState?.canPop() ?? false)) {
            key.currentState!.pop();
          }
        },
        child: Navigator(
          key: key,
          onGenerateRoute: (settings) =>
              MaterialPageRoute<void>(settings: settings, builder: rootBuilder),
        ),
      ),
    );
  }

  Widget _sectionRoot(int index, Widget child) {
    return Scaffold(
      appBar: index == 0
          ? null
          : AppBar(title: Text(_titles[index]), centerTitle: false),
      body: child,
      floatingActionButton: index == 0
          ? ValueListenableBuilder<double>(
              valueListenable: _assistantButtonLift,
              // Puja suaument fins a sobre de la targeta, en lloc de saltar.
              builder: (context, lift, child) => AnimatedPadding(
                duration: mapOverlayAnimationDuration,
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(bottom: lift),
                child: child,
              ),
              child: FloatingActionButton.extended(
                onPressed: _openAssistant,
                tooltip: 'Obrir l’assistent',
                icon: const Icon(Icons.smart_toy_outlined, size: 20),
                label: const Text('Assistent'),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          sizing: StackFit.expand,
          children: [
            _buildSectionNavigator(
              0,
              (context) => _sectionRoot(
                0,
                ActivitiesScreen(
                  viewModel: _activitiesViewModel,
                  enrollmentViewModel: _enrollmentViewModel,
                  onActivitySelected: _openActivityDetails,
                  mapViewModel: _activitiesMapViewModel,
                  onMapActivitySelected: (activityId) => _openActivityDetails(
                    activityId,
                    repository: widget.activityMapRepository,
                  ),
                  onCreatePressed: _openCreateActivity,
                  // El botó ja té 16 de marge: amb 12 menys queda a 12 de la
                  // targeta, com la llegenda.
                  onMapOverlayChanged: (overlay) => _assistantButtonLift.value =
                      overlay == 0 ? 0 : overlay - 4,
                ),
              ),
            ),
            _buildSectionNavigator(
              1,
              (context) => _sectionRoot(
                1,
                AgendaScreen(
                  userId: _enrollmentUserId,
                  enrollmentRepository: widget.enrollmentRepository,
                  activityRepository: _activityRepository,
                  onActivitySelected: _openActivityDetails,
                  activitiesChanged: _activitiesChanged,
                  participationActionBuilder: (activity) => EnrollmentAction(
                    viewModel: _enrollmentViewModel,
                    activityId: activity.id,
                    activityTitle: activity.title,
                  ),
                  ratingBuilder: _buildRating,
                  now: widget.now,
                ),
              ),
            ),
            _buildSectionNavigator(
              2,
              (context) => _sectionRoot(
                2,
                DiscoverScreen(
                  userId: widget.user.id,
                  repository: widget.discoveryRepository,
                  enrollmentViewModel: _enrollmentViewModel,
                  onSearchPressed: _openDiscoverySearch,
                  onActivitySelected: _openActivityDetails,
                ),
              ),
            ),
            _buildSectionNavigator(
              3,
              (context) => _sectionRoot(
                3,
                NotificationsScreen(
                  userId: widget.user.id,
                  repository: widget.notificationRepository,
                  onActivitySelected: (id) {
                    // A late read confirmation must not open another tab's route.
                    if (_selectedIndex == 3) _openActivityDetails(id);
                  },
                ),
              ),
            ),
            _buildSectionNavigator(
              4,
              (context) => ProfileScreen(
                viewModel: _profileViewModel,
                onSettingsPressed: _openProfileSettings,
                onSharePressed: widget.user.username?.isNotEmpty == true
                    ? _shareOwnProfile
                    : null,
                onActivitySelected: _openActivityDetails,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isAssistantOpen
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Inici',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Agenda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search),
                  label: 'Descobreix',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: 'Avisos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
            ),
    );
  }
}

//Para el menu de navegación inferior, se ha utilizado un IndexedStack para mantener el estado de cada pantalla mientras se navega entre ellas. Esto permite que los usuarios puedan volver a una pantalla anterior sin perder su estado actual.
