import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../formatters/activity_date_formatter.dart';
import 'activity_badges.dart';
import 'activity_information_row.dart';
import 'activity_image.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.participationAction,
  });

  final Activity activity;
  final VoidCallback onTap;
  final Widget? participationAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final creator = activity.creator;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      // Tocar qualsevol lloc obre l'activitat; els botons de dins fan la
      // seva acció. Per al lector de pantalla, la imatge i el títol ja són
      // els botons per obrir-la.
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (creator != null) ...[
                Row(
                  children: [
                    ClipOval(
                      // Sense foto (qui crea una activitat no en té) es mostra
                      // la mateixa icona que si la foto no es pot carregar.
                      child: switch (creator.avatarAsset) {
                        final avatar? => Image.asset(
                          avatar,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _AvatarPlaceholder(),
                        ),
                        null => const _AvatarPlaceholder(),
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Publicat per ${creator.name}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (creator.isFriend) ...[
                      const SizedBox(width: 8),
                      const FriendshipBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: onTap,
                          child: ActivityImage(
                            activity: activity,
                            semanticLabel: 'Veure activitat: ${activity.title}',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ActivityCategoriesSummary(
                          categories: activity.categories,
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: onTap,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    activity.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (activity.municipality.isNotEmpty) ...[
                          ActivityInformationRow(
                            icon: Icons.location_on_outlined,
                            text: activity.municipality,
                          ),
                          const SizedBox(height: 6),
                        ],
                        ActivityInformationRow(
                          icon: Icons.calendar_today_outlined,
                          text: formatActivityWhen(activity),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (activity.source == ActivitySource.culturalAgenda) ...[
                const SizedBox(height: 12),
                Text(
                  'Font: Agenda Cultural · Generalitat',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (participationAction != null) ...[
                const SizedBox(height: 12),
                participationAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 32,
      height: 32,
      child: Icon(Icons.person_outline),
    );
  }
}

//recibe un objeto Activity y construye su representación visual, la dibuja
//La mayor parte del código especifica cómo se colocan esos elementos, no operaciones de negocio.
