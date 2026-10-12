import 'package:flutter/material.dart';

import '../../features/activities/data/demo_activity_repository.dart';
import '../../features/activities/presentation/screens/activities_screen.dart';
import '../../features/activities/presentation/view_models/activities_view_model.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late final ActivitiesViewModel _activitiesViewModel;

  static const _titles = ['AProp!', 'Agenda', 'Descobreix', 'Avisos', 'Perfil'];

  @override
  void initState() {
    //flutter llama porque es la pantalla inicial de la app. Se crea el ViewModel y se carga la lista de actividades.
    super.initState();

    _activitiesViewModel = ActivitiesViewModel(
      repository: DemoActivityRepository(),
    );

    _activitiesViewModel.load(); //mientras espera ésto flutter dibuja un indicador de carga. Cuando termina, el ViewModel notifica a la pantalla y ésta se redibuja con la lista de actividades.
  }

  @override
  void dispose() {
    _activitiesViewModel.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? null
          : AppBar(title: Text(_titles[_selectedIndex]), centerTitle: false),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          sizing: StackFit.expand,
          children: [
            ActivitiesScreen(viewModel: _activitiesViewModel), //índice 0, pantalla de actividades. Se le pasa el ViewModel para que pueda acceder a la lista de actividades y al estado de carga. (asi se dibuja en pantalla la lista de actividades o el indicador de carga o el mensaje de error, esa  logica la lleva la screen)
            const Center(child: Text('Els teus plans culturals')),
            const Center(child: Text('Troba el teu pròxim pla')),
            const Center(child: Text('Els teus avisos')),
            const Center(child: Text('El teu perfil')),
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
