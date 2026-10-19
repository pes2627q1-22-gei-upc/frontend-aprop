import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../../../activities/presentation/widgets/activity_card.dart';
import '../../models/assistant_message.dart';

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({
    super.key,
    required this.message,
    required this.onActivitySelected,
    this.participationActionBuilder,
  });

  final AssistantMessage message;
  final ValueChanged<String> onActivitySelected;
  final Widget Function(Activity activity)? participationActionBuilder;

  @override
  Widget build(BuildContext context) {
    if (message.sender == AssistantMessageSender.user) {
      return _UserBubble(message: message);
    }
    return _AssistantBubble(
      message: message,
      onActivitySelected: onActivitySelected,
      participationActionBuilder: participationActionBuilder,
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Semantics(
            container: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: colors.onPrimary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Tu',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({
    required this.message,
    required this.onActivitySelected,
    this.participationActionBuilder,
  });

  final AssistantMessage message;
  final ValueChanged<String> onActivitySelected;
  final Widget Function(Activity activity)? participationActionBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final interpretation = message.interpretation;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Assistent',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (interpretation != null && interpretation.hasAny) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (interpretation.category != null)
                              _InterpretationChip(
                                icon: Icons.category_outlined,
                                label: 'Tipus: ${interpretation.category}',
                              ),
                            if (interpretation.municipality != null)
                              _InterpretationChip(
                                icon: Icons.location_on_outlined,
                                label:
                                    'Municipi: ${interpretation.municipality}',
                              ),
                            if (interpretation.dateRange != null)
                              _InterpretationChip(
                                icon: Icons.date_range_outlined,
                                label: 'Dates: ${interpretation.dateRange}',
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        message.text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            for (final activity in message.recommendedActivities) ...[
              const SizedBox(height: 12),
              ActivityCard(
                key: ValueKey('assistant-card-${message.id}-${activity.id}'),
                activity: activity,
                onTap: () => onActivitySelected(activity.id),
                participationAction: participationActionBuilder?.call(activity),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InterpretationChip extends StatelessWidget {
  const _InterpretationChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
