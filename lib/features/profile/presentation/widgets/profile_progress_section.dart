import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../formatters/profile_level_formatter.dart';
import 'profile_palette.dart';

class ProfileProgressSection extends StatelessWidget {
  const ProfileProgressSection({super.key, required this.progress});
  final ProfileProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ProfilePalette>()!;
    if (progress.level == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${progress.experience} XP',
          style: theme.textTheme.titleSmall,
        ),
      );
    }
    final levels = ProfileLevel.values;
    final remaining = progress.remainingExperience;
    final next = progress.level == ProfileLevel.ambassador
        ? null
        : levels[progress.level!.index + 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = math.max(
              constraints.maxWidth / levels.length,
              MediaQuery.textScalerOf(context).scale(100),
            );
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final level in levels)
                    SizedBox(
                      width: width,
                      child: _LevelBadge(
                        level: level,
                        current: progress.level!,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              progress.nextLevelTarget == null
                  ? '${progress.experience} XP'
                  : '${progress.experience} / ${progress.nextLevelTarget} XP',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              next == null
                  ? 'Has assolit el nivell màxim'
                  : remaining == null
                  ? 'El teu recorregut cultural comença aquí'
                  : '$remaining XP per a ${next.fullLabel}',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.fraction,
            minHeight: 8,
            backgroundColor: palette.lockedBackground,
            semanticsLabel: progress.nextLevelTarget == null
                ? 'Progrés d’experiència: ${progress.experience} XP'
                : 'Progrés d’experiència: ${progress.experience} de ${progress.nextLevelTarget} XP',
          ),
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.current});
  final ProfileLevel level;
  final ProfileLevel current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ProfilePalette>()!;
    final isCurrent = level == current;
    final reached = level.index <= current.index;
    final foreground = reached ? palette.goldInk : palette.lockedInk;
    final icon = !reached
        ? Icons.lock_outline
        : switch (level) {
            ProfileLevel.curious => Icons.visibility_outlined,
            ProfileLevel.explorer => Icons.explore_outlined,
            ProfileLevel.adventurer => Icons.hiking,
            ProfileLevel.discoverer => Icons.travel_explore,
            ProfileLevel.ambassador => Icons.workspace_premium_outlined,
          };
    return Semantics(
      label:
          '${level.fullLabel}: ${isCurrent
              ? 'nivell actual'
              : reached
              ? 'assolit'
              : 'pendent'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : reached
                        ? palette.gold
                        : palette.lockedBackground,
                    width: 2,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? palette.gold
                        : reached
                        ? palette.goldSoft
                        : palette.lockedBackground,
                  ),
                  child: Icon(icon, color: foreground, size: 26),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                level.label,
                softWrap: false,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : reached
                      ? theme.colorScheme.onSurface
                      : palette.lockedInk,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
