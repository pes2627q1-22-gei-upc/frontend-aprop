import 'package:flutter/material.dart';

import '../view_models/activities_view_model.dart';
import '../widgets/activities_header.dart';
import '../widgets/activity_card.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({
    super.key,
    required this.viewModel,
    required this.onActivitySelected,
  });

  final ActivitiesViewModel viewModel;
  final ValueChanged<String> onActivitySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // La llista és l'única vista implementada de moment.
        const ActivitiesHeader(selectedView: ActivitiesView.list),
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

        if (activities.isEmpty) {
          return const Center(child: Text('No hi ha activitats disponibles.'));
        }

        return ListView.separated(
          key: const PageStorageKey<String>('activities-list'),
          padding: const EdgeInsets.all(16),
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
            );
          },
        );
      },
    );
  }
}
