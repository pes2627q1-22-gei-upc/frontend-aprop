import 'package:flutter/material.dart';

import '../../features/activities/models/activity.dart';
import '../../features/activities/presentation/screens/activities_screen.dart';
import '../../features/activities/presentation/screens/create_activity_screen.dart';
import '../../features/activities/presentation/view_models/activities_view_model.dart';
import '../../features/activities/presentation/view_models/enrollment_view_model.dart';
import '../../features/activities/presentation/widgets/enrollment_action.dart';
import '../../features/activities/repositories/activity_repository.dart';
import '../../features/activities/repositories/enrollment_repository.dart';
import '../../features/agenda/presentation/screens/agenda_screen.dart';
import '../../features/assistant/presentation/screens/assistant_screen.dart';
import '../../features/assistant/presentation/view_models/assistant_view_model.dart';
import '../../features/assistant/repositories/assistant_repository.dart';
import '../../features/auth/models/app_user.dart';
import 'activity_details_route.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.activityRepository,
    required this.enrollmentRepository,
    required this.assistantRepository,
  });

  final AppUser user;
  final VoidCallback onSignOut;
  final ActivityRepository activityRepository;
  final EnrollmentRepository enrollmentRepository;
  final AssistantRepository assistantRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final _sectionNavigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );
  late final ActivityRepository _activityRepository;
  late final ActivitiesViewModel _activitiesViewModel;
  late final EnrollmentViewModel _enrollmentViewModel;
  late final AssistantViewModel _assistantViewModel;

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
    _enrollmentViewModel.load();

    _activitiesViewModel.load(); //mientras espera ésto flutter dibuja un indicador de carga. Cuando termina, el ViewModel notifica a la pantalla y ésta se redibuja con la lista de actividades.
  }

  @override
  void dispose() {
    _activitiesViewModel.dispose();
    _enrollmentViewModel.dispose();
    _assistantViewModel.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;

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

  void _openCreateActivity() {
    final navigator = _sectionNavigatorKeys[0].currentState!;
    if (navigator.canPop()) return;
    navigator.push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/activities/new'),
        builder: (context) => CreateActivityScreen(
          repository: _activityRepository,
          creator: ActivityCreator(
            name: '${widget.user.firstName} ${widget.user.lastName}',
            isFriend: false,
          ),
          onCreated: (activity) => _showCreatedActivity(navigator, activity),
        ),
      ),
    );
  }

  /// Qui crea una activitat hi queda apuntat. Després es veu la seva fitxa en
  /// lloc del formulari i, en tornar enrere, la llista ja la inclou.
  // TODO(backend): quan el backend apunti la persona creadora en crear
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
    return NavigatorPopHandler<void>(
      enabled: _selectedIndex == index,
      onPopWithResult: (_) {
        if (_selectedIndex == index && (key.currentState?.canPop() ?? false)) {
          key.currentState!.pop();
        }
      },
      child: Navigator(
        key: key,
        onGenerateRoute: (settings) =>
            MaterialPageRoute<void>(settings: settings, builder: rootBuilder),
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
          ? FloatingActionButton.extended(
              onPressed: _openCreateActivity,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Crear activitat'),
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
                const Center(child: Text('Troba el teu pròxim pla')),
              ),
            ),
            _buildSectionNavigator(
              3,
              (context) =>
                  _sectionRoot(3, const Center(child: Text('Els teus avisos'))),
            ),
            _buildSectionNavigator(
              4,
              (context) => _sectionRoot(
                4,
                _ProfilePlaceholder(
                  user: widget.user,
                  onSignOut: widget.onSignOut,
                ),
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

/// Perfil provisional fins que hi hagi la funcionalitat de perfil: mostra qui
/// ha iniciat la sessió i permet tancar-la.
class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder({required this.user, required this.onSignOut});

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = user.username;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('El teu perfil'),
            const SizedBox(height: 16),
            Text(
              '${user.firstName} ${user.lastName}',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (username != null)
              Text(
                '@$username',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Tanca la sessió'),
            ),
          ],
        ),
      ),
    );
  }
}

//Para el menu de navegación inferior, se ha utilizado un IndexedStack para mantener el estado de cada pantalla mientras se navega entre ellas. Esto permite que los usuarios puedan volver a una pantalla anterior sin perder su estado actual.
