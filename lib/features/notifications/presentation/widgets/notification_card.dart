import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../formatters/notification_formatter.dart';
import 'notification_badge_theme.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onOpen,
    required this.onRespond,
    required this.profileAvailable,
    this.reading = false,
    this.responding = false,
    this.error,
    this.enabled = true,
  });

  final AppNotification notification;
  final VoidCallback onOpen;
  final ValueChanged<bool> onRespond;
  final bool profileAvailable;
  final bool reading;
  final bool responding;
  final String? error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final badgeTheme = theme.extension<NotificationBadgeTheme>();
    final notice = notification;
    final activity = notice.activity;
    final pendingRequest = notice.requestStatus == FriendRequestStatus.pending;
    final unavailableProfile = activity == null && !profileAvailable;
    final busy = reading || responding || !enabled;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: notice.isRead
          ? colors.surface
          : badgeTheme?.unreadBackground ??
                Color.alphaBlend(
                  colors.primary.withValues(alpha: 0.05),
                  colors.surface,
                ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: notice.isRead ? 'Llegit' : 'Sense llegir',
            hint: unavailableProfile
                ? 'Marca l’avís com a llegit. El perfil encara no està disponible.'
                : activity != null
                ? 'Obre l’activitat'
                : 'Obre el perfil',
            child: InkWell(
              onTap: busy ? null : onOpen,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NotificationAvatar(notification: notice),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _CategoryBadge(category: notice.category),
                              Text(
                                notificationTime(notice.receivedAt),
                                semanticsLabel:
                                    'Rebut a les ${notificationTime(notice.receivedAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notificationMessage(notice),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: notice.isRead
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                          ),
                          if (activity != null) ...[
                            const SizedBox(height: 8),
                            if (notice.type ==
                                NotificationType.recommendation) ...[
                              Text(
                                '${activity.category} · ${activity.municipality}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                            ],
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    notificationActivitySchedule(
                                      activity.startsAt,
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (unavailableProfile) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Perfil disponible properament',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (reading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (!unavailableProfile)
                      const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),
          ),
          if (pendingRequest)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (responding) ...[
                    const LinearProgressIndicator(
                      semanticsLabel: 'Enviant la resposta',
                    ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: busy ? null : () => onRespond(true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(120, 48),
                        ),
                        child: const Text('Acceptar'),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : () => onRespond(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(120, 48),
                        ),
                        child: const Text('Rebutjar'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else if (notice.requestStatus != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  notice.requestStatus == FriendRequestStatus.accepted
                      ? 'Sol·licitud acceptada'
                      : 'Sol·licitud rebutjada',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final person = notification.person;
    final fallback = CircleAvatar(
      radius: 24,
      backgroundColor: colors.surfaceContainerLow,
      foregroundColor: colors.primary,
      child: person != null
          ? Text(
              person.name
                  .split(' ')
                  .where((s) => s.isNotEmpty)
                  .take(2)
                  .map((s) => s[0])
                  .join(),
            )
          : Icon(
              notification.type == NotificationType.reminder
                  ? Icons.notifications_none
                  : Icons.lightbulb_outline,
            ),
    );
    final asset = person?.avatarAsset;
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (asset == null)
            fallback
          else
            ClipOval(
              child: Image.asset(
                asset,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
          if (!notification.isRead)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                key: ValueKey('notification-unread-${notification.id}'),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});
  final NotificationCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final badge = theme.extension<NotificationBadgeTheme>();
    final (background, foreground) = switch (category) {
      NotificationCategory.social => (
        badge?.socialBackground ?? colors.primaryContainer,
        badge?.socialForeground ?? colors.onPrimaryContainer,
      ),
      NotificationCategory.reminders => (
        badge?.reminderBackground ?? colors.primaryContainer,
        badge?.reminderForeground ?? colors.onPrimaryContainer,
      ),
      NotificationCategory.recommendations => (
        colors.primary.withValues(alpha: 0.08),
        colors.primary,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          notificationCategoryLabel(category),
          style: theme.textTheme.labelLarge?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
