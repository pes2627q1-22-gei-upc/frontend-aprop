import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/app_notification.dart';

/// Presentation only: the screen forwards actions to its ViewModel, which
/// owns pending operations and receives the repository's confirmed outcome.
class FriendRequestNotificationActions extends StatelessWidget {
  const FriendRequestNotificationActions({
    super.key,
    required this.notificationId,
    required this.senderName,
    required this.status,
    required this.onRespond,
    this.enabled = true,
    this.responding = false,
  });

  final String notificationId;
  final String senderName;
  final FriendRequestStatus status;
  final ValueChanged<bool> onRespond;
  final bool enabled;
  final bool responding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final available = enabled && !responding;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: status != FriendRequestStatus.pending
          ? Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      status == FriendRequestStatus.accepted
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status == FriendRequestStatus.accepted
                          ? l10n.notifRequestAccepted
                          : l10n.notifRequestDeclined,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (responding) ...[
                  Semantics(
                    liveRegion: true,
                    label: l10n.notifSendingResponse,
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          l10n.notifSendingResponse,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final accept = _action(
                      context: context,
                      label: l10n.notifAccept,
                      semanticsLabel: l10n.notifAcceptRequestFrom(senderName),
                      accept: true,
                      available: available,
                    );
                    final decline = _action(
                      context: context,
                      label: l10n.notifDecline,
                      semanticsLabel: l10n.notifDeclineRequestFrom(senderName),
                      accept: false,
                      available: available,
                    );
                    // Keep long/localized labels and enlarged text inside the card.
                    if (constraints.maxWidth < 280 ||
                        MediaQuery.textScalerOf(context).scale(14) > 21) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [accept, const SizedBox(height: 8), decline],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: accept),
                        const SizedBox(width: 12),
                        Expanded(child: decline),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _action({
    required BuildContext context,
    required String label,
    required String semanticsLabel,
    required bool accept,
    required bool available,
  }) {
    final colors = Theme.of(context).colorScheme;
    final callback = available ? () => onRespond(accept) : null;
    final text = Text(
      label,
      semanticsLabel: semanticsLabel,
      textAlign: TextAlign.center,
    );
    // Keep the native button's focus, keyboard actions and enabled semantics.
    return accept
        ? FilledButton(
            key: ValueKey('notification-accept-$notificationId'),
            onPressed: callback,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: text,
          )
        : OutlinedButton(
            key: ValueKey('notification-decline-$notificationId'),
            onPressed: callback,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
              side: available
                  ? null
                  : BorderSide(color: colors.onSurface.withValues(alpha: 0.12)),
            ),
            child: text,
          );
  }
}
