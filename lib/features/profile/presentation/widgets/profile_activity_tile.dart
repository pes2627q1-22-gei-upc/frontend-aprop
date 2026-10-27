import 'package:flutter/material.dart';

import '../../../../core/widgets/content_image.dart';

import '../../../activities/models/activity.dart';

class ProfileActivityTile extends StatelessWidget {
  const ProfileActivityTile({
    super.key,
    required this.activity,
    required this.onTap,
    this.rating,
  });
  final Activity activity;
  final int? rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onPrimary;
    return Semantics(
      button: true,
      onTap: onTap,
      label:
          'Veure activitat: ${activity.title}${rating == null ? '' : '. Valoració: $rating de 5'}',
      child: ExcludeSemantics(
        child: Material(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ContentImage(
                  url: activity.imageUrl,
                  asset: activity.imageAsset,
                  label: activity.title,
                  excludeFromSemantics: true,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.scrim.withValues(alpha: 0),
                        theme.colorScheme.scrim.withValues(alpha: .9),
                      ],
                    ),
                  ),
                ),
                if (rating != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.scrim.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: foreground),
                          const SizedBox(width: 2),
                          Text(
                            '$rating',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    activity.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
