import 'package:flutter/material.dart';

/// Five tappable stars. [score] null means not rated; with [isReadOnly] the
/// stars cannot be changed (already rated). While [isLoading] taps are ignored.
class StarRatingWidget extends StatelessWidget {
  const StarRatingWidget({
    super.key,
    required this.onSelected,
    this.score,
    this.isLoading = false,
    this.isReadOnly = false,
    this.errorMessage,
  });

  final ValueChanged<int> onSelected;
  final int? score;
  final bool isLoading;
  final bool isReadOnly;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = !isLoading && !isReadOnly;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Read-only: announce the rated value once instead of five stars.
            Semantics(
              container: isReadOnly && score != null,
              label: isReadOnly && score != null
                  ? 'Valoració: $score de 5'
                  : null,
              excludeSemantics: isReadOnly && score != null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var star = 1; star <= 5; star++)
                    Semantics(
                      button: true,
                      enabled: enabled,
                      selected: star == score,
                      label:
                          'Valora amb $star ${star == 1 ? 'estrella' : 'estrelles'}',
                      value: '$star de 5',
                      excludeSemantics: true,
                      onTap: enabled ? () => onSelected(star) : null,
                      child: IconButton(
                        key: ValueKey('star-$star'),
                        onPressed: enabled ? () => onSelected(star) : null,
                        icon: Icon(
                          star <= (score ?? 0) ? Icons.star : Icons.star_border,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Desant la valoració',
                  ),
                ),
              ),
          ],
        ),
        if (errorMessage != null)
          Text(
            errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}
