import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../view_models/rating_view_model.dart';
import 'star_rating_widget.dart';
import '../../../../core/l10n/locale_controller.dart';

/// «Com t’ha anat?» block bound to the shared [RatingViewModel]. The caller
/// decides when an activity can be rated. Once rated, the user can change or
/// delete their own rating.
class ActivityRating extends StatefulWidget {
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
        title: Text(context.l10n.ratingDeleteTitle),
        content: Text(context.l10n.ratingDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.delete),
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
              if (widget.organizer case final organizer?)
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
                          editing
                              ? context.l10n.ratingEdit
                              : rated
                              ? context.l10n.ratingOrganizerRated(
                                  organizer.name,
                                )
                              : context.l10n.ratingOrganizerAsk(organizer.name),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  editing
                      ? context.l10n.ratingEdit
                      : rated
                      ? context.l10n.ratingActivityRated
                      : context.l10n.ratingAsk,
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
                        child: Text(
                          context.l10n.cancel,
                          semanticsLabel: context.l10n.ratingCancelEdit,
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
                        child: Text(
                          context.l10n.ratingEditShort,
                          semanticsLabel: context.l10n.ratingEdit,
                        ),
                      ),
                    TextButton(
                      onPressed: busy ? null : _confirmDelete,
                      child: Text(
                        context.l10n.delete,
                        semanticsLabel: context.l10n.ratingDelete,
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
