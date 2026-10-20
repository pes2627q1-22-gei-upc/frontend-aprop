import 'package:flutter/material.dart';

import '../view_models/activities_view_model.dart';
import '../view_models/enrollment_view_model.dart';
import '../widgets/activities_header.dart';
import '../widgets/activities_map.dart';
import '../widgets/activity_card.dart';
import '../widgets/enrollment_action.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({
    super.key,
    required this.viewModel,
    required this.enrollmentViewModel,
    required this.onActivitySelected,
    this.onAssistantPressed,
    this.onMapOverlayChanged,
  });

  final ActivitiesViewModel viewModel;
  final EnrollmentViewModel enrollmentViewModel;
  final ValueChanged<String> onActivitySelected;
  final VoidCallback? onAssistantPressed;

  /// Espai que ocupa la targeta del mapa des de baix (0 si no n'hi ha), per
  /// apartar-hi el botó «Crear activitat».
  final ValueChanged<double>? onMapOverlayChanged;

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  // Mapa i llista mostren el mateix conjunt d'activitats. La llista és la
  // vista inicial: si Google Maps falla (p. ex. sense clau), Inici continua
  // funcionant (CA3 de la #21).
  // TODO(DP-022): el mockup (fig. 7) obre Inici amb el mapa.
  ActivitiesView _view = ActivitiesView.list;

  ActivitiesViewModel get viewModel => widget.viewModel;
  EnrollmentViewModel get enrollmentViewModel => widget.enrollmentViewModel;
  ValueChanged<String> get onActivitySelected => widget.onActivitySelected;

  void _show(ActivitiesView view) {
    if (view == _view) return;
    setState(() => _view = view);
    // A la llista no hi ha targeta del mapa: el botó torna a baix.
    if (view == ActivitiesView.list) widget.onMapOverlayChanged?.call(0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActivitiesHeader(
          selectedView: _view,
          onAssistantPressed: widget.onAssistantPressed,
          onMapPressed: () => _show(ActivitiesView.map),
          onListPressed: () => _show(ActivitiesView.list),
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        if (viewModel.isLoading) {
          //si el VM aun esta calculando la lista de actividades, se muestra un indicador de carga circular en el centro de la pantalla.
          return const Center(child: CircularProgressIndicator());
        }

        final errorMessage = viewModel.errorMessage;

        if (errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: viewModel.load,
                    child: const Text('Tornar-ho a provar'),
                  ),
                ],
              ),
            ),
          );
        }

        final activities = viewModel.activities;

        if (_view == ActivitiesView.map) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ActivitiesMap(
              activities: activities,
              onActivitySelected: onActivitySelected,
              onOverlayHeightChanged: widget.onMapOverlayChanged,
            ),
          );
        }

        if (activities.isEmpty) {
          return const Center(child: Text('No hi ha activitats disponibles.'));
        }

        return ListView.separated(
          key: const PageStorageKey<String>('activities-list'),
          // Marge inferior perquè el botó «Crear activitat» no tapi l'última
          // targeta.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: activities.length,
          separatorBuilder: (context, index) {
            return const SizedBox(height: 12);
          },
          itemBuilder: (context, index) {
            final activity = activities[index];

            return ActivityCard(
              key: ValueKey(activity.id),
              activity: activity,
              onTap: () => onActivitySelected(activity.id),
              participationAction: EnrollmentAction(
                viewModel: enrollmentViewModel,
                activityId: activity.id,
                activityTitle: activity.title,
              ),
            );
          },
        );
      },
    );
  }
}
