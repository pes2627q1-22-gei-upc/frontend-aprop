import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../view_models/rating_view_model.dart';
import 'star_rating_widget.dart';

/// «Com t’ha anat?» block bound to the shared [RatingViewModel]. The caller
/// decides when an activity can be rated.
class ActivityRating extends StatelessWidget {
  const ActivityRating({
    super.key,
    required this.viewModel,
    required this.activityId,
    this.organizer,
  });

  final RatingViewModel viewModel;
  final String activityId;

  /// Creator of a community activity (not the signed-in user): the rating
  /// is then about them (R9). Null for official activities.
  final ActivityCreator? organizer;

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
              if (organizer case final organizer?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: organizer.avatarAsset == null
                            ? null
                            : AssetImage(organizer.avatarAsset!),
                        child: organizer.avatarAsset == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rated
                              ? 'Ja has valorat ${organizer.name}'
                              : 'Com ha anat l’organitzador/a '
                                    '${organizer.name}?',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                )
              else
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
