import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../formatters/notification_formatter.dart';
import 'notification_badge_theme.dart';
import '../../../../core/l10n/locale_controller.dart';

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
    final unavailableProfile =
        notice.activityId == null && notice.person != null && !profileAvailable;
    final hasDestination =
        notice.canOpenActivity ||
        (notice.activityId == null &&
            notice.person != null &&
            profileAvailable);
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
            label: notice.isRead
                ? context.l10n.notifRead
                : context.l10n.notifUnread,
            hint: unavailableProfile
                ? context.l10n.notifHintProfileUnavailable
                : notice.canOpenActivity
                ? context.l10n.notifHintOpenActivity
                : hasDestination
                ? context.l10n.notifHintOpenProfile
                : context.l10n.notifHintMarkRead,
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
                                semanticsLabel: context.l10n.notifReceivedAt(
                                  notificationTime(notice.receivedAt),
                                ),
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
                                [
                                  activity.category,
                                  activity.municipality,
                                ].where((text) => text.isNotEmpty).join(' · '),
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
                              context.l10n.notifProfileSoon,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                          if (notice.activityId != null &&
                              activity == null) ...[
                            const SizedBox(height: 8),
                            Text(
                              notice.activityUnavailable
                                  ? context.l10n.notifActivityGone
                                  : context.l10n.notifActivityLoadError,
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
                    else if (hasDestination)
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
                    LinearProgressIndicator(
                      semanticsLabel: context.l10n.notifSendingResponse,
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
                        child: Text(context.l10n.notifAccept),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : () => onRespond(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(120, 48),
                        ),
                        child: Text(context.l10n.notifDecline),
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
                      ? context.l10n.notifRequestAccepted
                      : context.l10n.notifRequestDeclined,
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
          : Icon(switch (notification.category) {
              NotificationCategory.reminders => Icons.notifications_none,
              NotificationCategory.recommendations => Icons.lightbulb_outline,
              NotificationCategory.social => Icons.people_outline,
              null => Icons.info_outline,
            }),
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
  final NotificationCategory? category;

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
      null => (colors.surfaceContainerLow, colors.onSurface),
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
