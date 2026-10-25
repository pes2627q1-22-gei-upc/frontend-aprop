import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/activities/data/demo_location_repository.dart';
import '../../features/activities/models/activity.dart';
import '../../features/activities/presentation/screens/activities_screen.dart';
import '../../features/activities/presentation/screens/activity_search_screen.dart';
import '../../features/activities/presentation/screens/create_activity_screen.dart';
import '../../features/activities/presentation/screens/discover_screen.dart';
import '../../features/activities/presentation/widgets/activities_map.dart';
import '../../features/activities/presentation/view_models/activities_view_model.dart';
import '../../features/activities/presentation/view_models/enrollment_view_model.dart';
import '../../features/activities/presentation/widgets/enrollment_action.dart';
import '../../features/activities/repositories/activity_repository.dart';
import '../../features/activities/repositories/discovery_repository.dart';
import '../../features/activities/repositories/enrollment_repository.dart';
import '../../features/agenda/presentation/screens/agenda_screen.dart';
import '../../features/assistant/presentation/screens/assistant_screen.dart';
import '../../features/assistant/presentation/view_models/assistant_view_model.dart';
import '../../features/assistant/repositories/assistant_repository.dart';
import '../../features/auth/models/app_user.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/repositories/notification_repository.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/profile_settings_screen.dart';
import '../../features/profile/presentation/view_models/profile_view_model.dart';
import '../../features/profile/repositories/profile_repository.dart';
import '../../features/profile/repositories/profile_settings_repository.dart';
import 'activity_details_route.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.activityRepository,
    required this.enrollmentRepository,
    required this.assistantRepository,
    required this.notificationRepository,
    required this.discoveryRepository,
    required this.profileRepository,
    required this.profileSettingsRepository,
  });

  final AppUser user;
  final Future<void> Function() onSignOut;
  final ActivityRepository activityRepository;
  final EnrollmentRepository enrollmentRepository;
  final AssistantRepository assistantRepository;
  final NotificationRepository notificationRepository;
  final DiscoveryRepository discoveryRepository;
  final ProfileRepository profileRepository;
  final ProfileSettingsRepository profileSettingsRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  /// Quant ha de pujar «Crear activitat» perquè no el tapi la targeta del mapa.
  final _createButtonLift = ValueNotifier<double>(0);
  final _sectionNavigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );
  late final ActivityRepository _activityRepository;
  late final ActivitiesViewModel _activitiesViewModel;
  late final EnrollmentViewModel _enrollmentViewModel;
  late final AssistantViewModel _assistantViewModel;
  late final ProfileViewModel _profileViewModel;

  static const _titles = ['AProp!', 'Agenda', 'Descobreix', 'Avisos', 'Perfil'];

  @override
  void initState() {
    //flutter llama porque es la pantalla inicial de la app. Se crea el ViewModel y se carga la lista de actividades.
    super.initState();

    _activityRepository = widget.activityRepository;
    _activitiesViewModel = ActivitiesViewModel(repository: _activityRepository);
    _enrollmentViewModel = EnrollmentViewModel(
      userId: widget.user.id,
      repository: widget.enrollmentRepository,
    );
    _assistantViewModel = AssistantViewModel(
      repository: widget.assistantRepository,
    );
    _profileViewModel = ProfileViewModel(
      user: widget.user,
      repository: widget.profileRepository,
    )..load();
    _enrollmentViewModel.load();

    _activitiesViewModel.load(); //mientras espera ésto flutter dibuja un indicador de carga. Cuando termina, el ViewModel notifica a la pantalla y ésta se redibuja con la lista de actividades.
  }

  @override
  void dispose() {
    _createButtonLift.dispose();
    _activitiesViewModel.dispose();
    _enrollmentViewModel.dispose();
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

  void _openActivityDetails(String activityId) {
    final navigator = _sectionNavigatorKeys[_selectedIndex].currentState!;
    // The callback comes from a section root; ignore repeated taps in transit.
    if (navigator.canPop()) return;
    navigator.push<void>(
      activityDetailsRoute(
        activityId: activityId,
        repository: _activityRepository,
        enrollmentViewModel: _enrollmentViewModel,
      ),
    );
  }

  void _openAssistant() {
    final navigator = _sectionNavigatorKeys[0].currentState!;
    if (navigator.canPop()) return;
    navigator.push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/assistant'),
        builder: (context) => AssistantScreen(
          viewModel: _assistantViewModel,
          onActivitySelected: (activityId) {
            if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
            Navigator.of(context).push<void>(
              activityDetailsRoute(
                activityId: activityId,
                repository: _activityRepository,
                enrollmentViewModel: _enrollmentViewModel,
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
              ),
            );
          },
        ),
      ),
    );
  }

  void _openCreateActivity() {
    final navigator = _sectionNavigatorKeys[0].currentState!;
    if (navigator.canPop()) return;
    navigator.push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/activities/new'),
        builder: (context) => CreateActivityScreen(
          repository: _activityRepository,
          locationRepository: const DemoLocationRepository(),
          creator: ActivityCreator(
            name: widget.user.fullName,
            userId: widget.user.id,
            isFriend: false,
          ),
          onCreated: (activity) => _showCreatedActivity(navigator, activity),
        ),
      ),
    );
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
        ),
      ),
    );
  }

  // TODO(DP-032): Share a real public link when a profile route is agreed.
  void _shareOwnProfile() {
    final username = widget.user.username;
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
    _activitiesViewModel.load();
    navigator.pushReplacement<void, void>(
      activityDetailsRoute(
        activityId: activity.id,
        repository: _activityRepository,
        enrollmentViewModel: _enrollmentViewModel,
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
              valueListenable: _createButtonLift,
              // Puja suaument fins a sobre de la targeta, en lloc de saltar.
              builder: (context, lift, child) => AnimatedPadding(
                duration: mapOverlayAnimationDuration,
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(bottom: lift),
                child: child,
              ),
              child: FloatingActionButton.extended(
                onPressed: _openCreateActivity,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Crear activitat'),
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
                  onAssistantPressed: _openAssistant,
                  // El botó ja té 16 de marge: amb 12 menys queda a 12 de la
                  // targeta, com la llegenda.
                  onMapOverlayChanged: (overlay) =>
                      _createButtonLift.value = overlay == 0 ? 0 : overlay - 4,
                ),
              ),
            ),
            _buildSectionNavigator(
              1,
              (context) => _sectionRoot(
                1,
                AgendaScreen(
                  userId: widget.user.id,
                  enrollmentRepository: widget.enrollmentRepository,
                  activityRepository: _activityRepository,
                  onActivitySelected: _openActivityDetails,
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
      bottomNavigationBar: NavigationBar(
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
