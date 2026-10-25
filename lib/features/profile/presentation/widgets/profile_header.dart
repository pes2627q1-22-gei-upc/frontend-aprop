import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../formatters/profile_level_formatter.dart';
import 'profile_palette.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onShare,
  });

  final UserProfile profile;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ProfilePalette>()!;
    final statistics = Row(
      children: [
        _Statistic(value: '${profile.completedPlans.length}', label: 'Plans'),
        _Statistic(value: '${profile.friendCount}', label: 'Amics'),
        _Statistic(
          value:
              profile.organizerRating
                  ?.toStringAsFixed(1)
                  .replaceAll('.', ',') ??
              '—',
          label: 'Valoració',
          star: profile.organizerRating != null,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final avatar = _ProfileAvatar(profile: profile);
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
                  profile.progress.level.label,
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
  });
  final String value;
  final String label;
  final bool star;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
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
              child: profile.avatarAsset == null
                  ? const Icon(Icons.person_outline, size: 56)
                  : Image.asset(
                      profile.avatarAsset!,
                      fit: BoxFit.cover,
                      semanticLabel: 'Foto de ${profile.displayName}',
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.person_outline, size: 56),
                    ),
            ),
          ),
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
                switch (profile.progress.level) {
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
