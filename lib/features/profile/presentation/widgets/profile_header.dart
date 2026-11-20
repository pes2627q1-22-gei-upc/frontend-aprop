import 'package:flutter/material.dart';

import '../../../../core/formatters/reliability_formatter.dart';
import '../../../../core/widgets/content_image.dart';

import '../../models/user_profile.dart';
import '../formatters/profile_level_formatter.dart';
import 'profile_palette.dart';
import '../../../../core/l10n/locale_controller.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onShare,
    this.onChangeAvatar,
    this.isChangingAvatar = false,
    this.showAvatarAction = false,
    this.showEdit = true,
    this.primaryAction,
    this.onFriendsPressed,
  });

  final UserProfile profile;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onChangeAvatar;
  final bool isChangingAvatar;
  final bool showAvatarAction;

  /// False on another person's profile: only «Compartir perfil» is shown.
  final bool showEdit;

  /// Takes the place of «Editar perfil» when [showEdit] is false (for
  /// example, the friend button on another person's profile).
  final Widget? primaryAction;

  /// Opens the friends list (#54); null leaves the counter as a number.
  final VoidCallback? onFriendsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ProfilePalette>()!;
    final statistics = Row(
      children: [
        _Statistic(
          value: '${profile.displayedPlanCount}',
          label: context.l10n.statPlans,
        ),
        _Statistic(
          key: const ValueKey('profile-friends-count'),
          value: '${profile.friendCount}',
          label: context.l10n.statFriends,
          onTap: onFriendsPressed,
          tapHint: context.l10n.friendsOpenList,
        ),
        _Statistic(
          value: formatReliability(profile.organizerRating),
          label: context.l10n.statRating,
          semanticsLabel: profile.organizerRating == null
              ? context.l10n.reliabilityNone
              : context.l10n.reliabilityOutOfFive(
                  formatReliability(profile.organizerRating),
                ),
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
                      isChangingAvatar
                          ? context.l10n.changing
                          : context.l10n.changePhoto,
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
            if (showEdit) ...[
              Expanded(
                child: FilledButton(
                  onPressed: onEdit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.l10n.editProfileTitle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else if (primaryAction case final action?) ...[
              Expanded(child: action),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Tooltip(
                message: onShare == null
                    ? context.l10n.shareNeedsUsername
                    : context.l10n.shareUsername,
                child: OutlinedButton(
                  onPressed: onShare,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.l10n.shareProfile,
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
    super.key,
    required this.value,
    required this.label,
    this.star = false,
    this.semanticsLabel,
    this.onTap,
    this.tapHint,
  });
  final String value;
  final String? semanticsLabel;
  final String label;
  final bool star;
  final VoidCallback? onTap;
  final String? tapHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Semantics(
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
    );
    return Expanded(
      child: onTap == null
          ? content
          : Semantics(
              button: true,
              hint: tapHint,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  // 48 dp: superfície tàctil mínima.
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: content,
                  ),
                ),
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
                label: context.l10n.photoOf(profile.displayName),
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
