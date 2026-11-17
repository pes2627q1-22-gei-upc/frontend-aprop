import 'package:flutter/material.dart';

import '../view_models/rating_view_model.dart';
import 'star_rating_widget.dart';

/// «Com t’ha anat?» block bound to the shared [RatingViewModel]. The caller
/// decides when an activity can be rated.
class ActivityRating extends StatelessWidget {
  const ActivityRating({
    super.key,
    required this.viewModel,
    required this.activityId,
  });

  final RatingViewModel viewModel;
  final String activityId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final rated = viewModel.hasRated(activityId);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rated ? 'Ja has valorat aquesta activitat' : 'Com t’ha anat?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              // Rated earlier (score unknown): the text alone, no empty stars.
              if (!rated || viewModel.scoreFor(activityId) != null)
                StarRatingWidget(
                  score: viewModel.scoreFor(activityId),
                  isLoading: viewModel.isSubmitting(activityId),
                  isReadOnly: rated,
                  errorMessage: viewModel.errorFor(activityId),
                  onSelected: (score) => viewModel.submit(activityId, score),
                ),
            ],
          ),
        );
      },
    );
  }
}
