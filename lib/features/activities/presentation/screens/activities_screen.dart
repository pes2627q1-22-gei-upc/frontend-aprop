import 'package:flutter/material.dart';

import '../view_models/activities_map_view_model.dart';
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
    this.mapViewModel,
    this.onMapActivitySelected,
  });

  final ActivitiesViewModel viewModel;
  final EnrollmentViewModel enrollmentViewModel;
  final ValueChanged<String> onActivitySelected;
  final VoidCallback? onAssistantPressed;

  /// Si hi és, el mapa carrega les activitats per zona visible (backend) en
  /// lloc de mostrar les de la llista.
  // TODO(DP-029): mapa i llista haurien de tenir el mateix conjunt d'activitats.
  final ActivitiesMapViewModel? mapViewModel;

  /// Obre una activitat del mapa quan ve d'una altra font que la llista. Per
  /// defecte, [onActivitySelected].
  final ValueChanged<String>? onMapActivitySelected;

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
    final mapViewModel = widget.mapViewModel;
    if (_view == ActivitiesView.map && mapViewModel != null) {
      return _buildAreaMap(mapViewModel);
    }

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

  /// Mapa que carrega la zona visible. Mentre carrega o si falla, continua
  /// mostrant les activitats que ja tenia.
  Widget _buildAreaMap(ActivitiesMapViewModel mapViewModel) {
    return ListenableBuilder(
      listenable: mapViewModel,
      builder: (context, child) {
        final errorMessage = mapViewModel.errorMessage;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Stack(
            children: [
              Positioned.fill(
                child: ActivitiesMap(
                  activities: mapViewModel.activities,
                  onActivitySelected:
                      widget.onMapActivitySelected ?? onActivitySelected,
                  onOverlayHeightChanged: widget.onMapOverlayChanged,
                  onVisibleAreaChanged: mapViewModel.loadArea,
                ),
              ),
              if (mapViewModel.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    semanticsLabel: 'Carregant les activitats de la zona',
                  ),
                ),
              if (errorMessage != null)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _MapErrorBanner(
                    message: errorMessage,
                    onRetry: mapViewModel.retry,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MapErrorBanner extends StatelessWidget {
  const _MapErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tornar-ho a provar'),
            ),
          ],
        ),
      ),
    );
  }
}
