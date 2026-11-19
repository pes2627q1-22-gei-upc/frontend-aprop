import 'package:flutter/material.dart';

import '../../../../core/formatters/reliability_formatter.dart';
import '../../../../core/widgets/content_image.dart';

import '../../models/user_profile.dart';
import '../formatters/profile_level_formatter.dart';
import 'profile_palette.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onShare,
    this.onChangeAvatar,
    this.isChangingAvatar = false,
    this.showAvatarAction = false,
  });

  final UserProfile profile;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onChangeAvatar;
  final bool isChangingAvatar;
  final bool showAvatarAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ProfilePalette>()!;
    final statistics = Row(
      children: [
        _Statistic(value: '${profile.displayedPlanCount}', label: 'Plans'),
        _Statistic(value: '${profile.friendCount}', label: 'Amics'),
        _Statistic(
          value: formatReliability(profile.organizerRating),
          label: 'Valoració',
          semanticsLabel: profile.organizerRating == null
              ? 'Fiabilitat com a organitzador: sense valoracions'
              : 'Fiabilitat com a organitzador: '
                    '${formatReliability(profile.organizerRating)} sobre 5',
          star: profile.organizerRating != null,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final avatar = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileAvatar(profile: profile),
                if (showAvatarAction)
                  TextButton.icon(
                    onPressed: isChangingAvatar ? null : onChangeAvatar,
                    icon: isChangingAvatar
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      isChangingAvatar ? 'Canviant…' : 'Canviar foto',
                    ),
                  ),
              ],
            );
            if (constraints.maxWidth < 330 ||
                MediaQuery.textScalerOf(context).scale(14) > 21) {
              return Column(
                children: [
                  Center(child: avatar),
                  const SizedBox(height: 16),
                  statistics,
                ],
              );
            }
            return Row(
              children: [
                avatar,
                const SizedBox(width: 16),
                Expanded(child: statistics),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              profile.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (profile.progress.level case final level?)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    level.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.goldInk,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (profile.biography.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(profile.biography, style: theme.textTheme.bodyLarge),
        ],
        if (profile.municipality.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 20),
              const SizedBox(width: 4),
              Expanded(child: Text(profile.municipality)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FilledButton(
                onPressed: onEdit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Editar perfil', textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Tooltip(
                message: onShare == null
                    ? 'Cal un nom d’usuari per compartir el perfil'
                    : 'Compartir el nom d’usuari',
                child: OutlinedButton(
                  onPressed: onShare,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Compartir perfil',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Statistic extends StatelessWidget {
  const _Statistic({
    required this.value,
    required this.label,
    this.star = false,
    this.semanticsLabel,
  });
  final String value;
  final String? semanticsLabel;
  final String label;
  final bool star;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Semantics(
        label: semanticsLabel,
        excludeSemantics: semanticsLabel != null,
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (star)
                  Icon(
                    Icons.star,
                    size: 18,
                    color: theme.extension<ProfilePalette>()!.goldInk,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<ProfilePalette>()!;
    return SizedBox(
      width: 96,
      height: 100,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 2),
            ),
            child: ClipOval(
              child: ContentImage(
                url: profile.avatarUrl,
                asset: profile.avatarAsset,
                label: 'Foto de ${profile.displayName}',
                placeholderIcon: Icons.person_outline,
              ),
            ),
          ),
          if (profile.progress.level case final level?)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.gold,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 3,
                  ),
                ),
                child: Icon(
                  switch (level) {
                    ProfileLevel.curious => Icons.visibility_outlined,
                    ProfileLevel.explorer => Icons.explore_outlined,
                    ProfileLevel.adventurer => Icons.hiking,
                    ProfileLevel.discoverer => Icons.travel_explore,
                    ProfileLevel.ambassador => Icons.workspace_premium_outlined,
                  },
                  size: 20,
                  color: palette.goldInk,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
