import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../../models/assistant_message.dart';
import 'assistant_activity_tile.dart';

class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({
    super.key,
    required this.message,
    required this.onActivitySelected,
    this.participationActionBuilder,
    this.rating,
    this.onRate,
    this.onOpenScreen,
  });

  final AssistantMessage message;
  final ValueChanged<String> onActivitySelected;
  final Widget Function(Activity activity)? participationActionBuilder;

  /// Selected rating (true = useful). [onRate] null hides the thumbs.
  final bool? rating;
  final ValueChanged<bool>? onRate;
  final ValueChanged<AssistantScreenTarget>? onOpenScreen;

  @override
  Widget build(BuildContext context) {
    if (message.sender == AssistantMessageSender.user) {
      return _UserBubble(message: message);
    }
    return _AssistantBubble(
      message: message,
      onActivitySelected: onActivitySelected,
      participationActionBuilder: participationActionBuilder,
      rating: rating,
      onRate: onRate,
      onOpenScreen: onOpenScreen,
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
            label: 'Tu',
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
    this.rating,
    this.onRate,
    this.onOpenScreen,
  });

  final AssistantMessage message;
  final ValueChanged<String> onActivitySelected;
  final Widget Function(Activity activity)? participationActionBuilder;
  final bool? rating;
  final ValueChanged<bool>? onRate;
  final ValueChanged<AssistantScreenTarget>? onOpenScreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final action = message.action;
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
              label: 'Assistent',
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
                      if (interpretation != null && interpretation.hasAny) ...[
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
                      if (interpretation != null && interpretation.hasAny)
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
              const SizedBox(height: 8),
              AssistantActivityTile(
                key: ValueKey('assistant-card-${message.id}-${activity.id}'),
                activity: activity,
                onTap: () => onActivitySelected(activity.id),
                participationAction: participationActionBuilder?.call(activity),
              ),
            ],
            if (action != null && onOpenScreen != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    button: true,
                    label: _screenLabel(action),
                    excludeSemantics: true,
                    child: FilledButton.tonalIcon(
                      key: ValueKey('assistant-action-${message.id}'),
                      onPressed: () => onOpenScreen!(action),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(_screenLabel(action)),
                    ),
                  ),
                ),
              ),
            if (onRate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ThumbButton(
                      key: ValueKey('assistant-thumb-up-${message.id}'),
                      helpful: true,
                      selected: rating == true,
                      onPressed: () => onRate!(true),
                    ),
                    _ThumbButton(
                      key: ValueKey('assistant-thumb-down-${message.id}'),
                      helpful: false,
                      selected: rating == false,
                      onPressed: () => onRate!(false),
                    ),
                  ],
                ),
              ),
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

String _screenLabel(AssistantScreenTarget target) => switch (target) {
  AssistantScreenTarget.home => 'Obre Inici',
  AssistantScreenTarget.agenda => 'Obre Agenda',
  AssistantScreenTarget.discover => 'Obre Descobreix',
  AssistantScreenTarget.notifications => 'Obre Avisos',
  AssistantScreenTarget.profile => 'Obre Perfil',
  AssistantScreenTarget.settings => 'Obre Configuració',
};

/// Thumb with a 48x48 target. The selected state changes the icon (filled vs
/// outlined) and a tonal background, not only the colour.
class _ThumbButton extends StatelessWidget {
  const _ThumbButton({
    super.key,
    required this.helpful,
    required this.selected,
    required this.onPressed,
  });

  final bool helpful;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = helpful ? 'Resposta útil' : 'Resposta poc útil';
    final icon = helpful
        ? (selected ? Icons.thumb_up : Icons.thumb_up_outlined)
        : (selected ? Icons.thumb_down : Icons.thumb_down_outlined);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      value: selected ? 'Seleccionat' : null,
      excludeSemantics: true,
      child: IconButton.filledTonal(
        tooltip: label,
        isSelected: selected,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        style: selected
            ? null
            : IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(icon, key: ValueKey(icon)),
        ),
      ),
    );
  }
}
