import 'package:flutter/material.dart';

import '../view_models/rating_view_model.dart';
import 'star_rating_widget.dart';

/// «Com t’ha anat?» block bound to the shared [RatingViewModel]. The caller
/// decides when an activity can be rated. Once rated, the user can change or
/// delete their own rating.
class ActivityRating extends StatefulWidget {
  const ActivityRating({
    super.key,
    required this.viewModel,
    required this.activityId,
  });

  final RatingViewModel viewModel;
  final String activityId;

  @override
  State<ActivityRating> createState() => _ActivityRatingState();
}

class _ActivityRatingState extends State<ActivityRating> {
  bool _editing = false;

  RatingViewModel get _viewModel => widget.viewModel;
  String get _id => widget.activityId;

  Future<void> _update(int score) async {
    final ok = await _viewModel.update(_id, score);
    // Stay editing after a failure, unless the rating is gone.
    if (mounted) setState(() => _editing = !ok && _viewModel.hasRated(_id));
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar la valoració?'),
        content: const Text(
          'La teva valoració s’eliminarà i podràs tornar a valorar l’activitat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel·la'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _viewModel.remove(_id);
    if (mounted && !_viewModel.hasRated(_id)) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final rated = _viewModel.hasRated(_id);
        final editing = rated && _editing;
        final busy = _viewModel.isSubmitting(_id);
        final score = _viewModel.scoreFor(_id);
        final error = _viewModel.errorFor(_id);
        // Rated earlier (score unknown): no stars unless the user is editing.
        final showStars = !rated || score != null || editing;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editing
                    ? 'Modifica la valoració'
                    : rated
                    ? 'Ja has valorat aquesta activitat'
                    : 'Com t’ha anat?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (showStars)
                StarRatingWidget(
                  score: score,
                  isLoading: busy,
                  isReadOnly: rated && !editing,
                  errorMessage: error,
                  onSelected: (value) =>
                      editing ? _update(value) : _viewModel.submit(_id, value),
                )
              else if (error != null)
                Text(
                  error,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              if (rated)
                Wrap(
                  children: [
                    if (editing)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () {
                                _viewModel.clearError(_id);
                                setState(() => _editing = false);
                              },
                        child: const Text(
                          'Cancel·la',
                          semanticsLabel: 'Cancel·la la modificació',
                        ),
                      )
                    else
                      TextButton(
                        onPressed: busy
                            ? null
                            : () {
                                _viewModel.clearError(_id);
                                setState(() => _editing = true);
                              },
                        child: const Text(
                          'Modifica',
                          semanticsLabel: 'Modifica la valoració',
                        ),
                      ),
                    TextButton(
                      onPressed: busy ? null : _confirmDelete,
                      child: const Text(
                        'Elimina',
                        semanticsLabel: 'Elimina la valoració',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
