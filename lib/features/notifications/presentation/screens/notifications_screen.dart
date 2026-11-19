import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../repositories/notification_repository.dart';
import '../formatters/notification_formatter.dart';
import '../view_models/notifications_view_model.dart';
import '../widgets/notification_card.dart';
import '../../../../core/l10n/locale_controller.dart';

/// Section content; MainShell owns the AppBar and bottom navigation.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.userId,
    required this.repository,
    required this.onActivitySelected,
    this.onPersonSelected,
    this.now,
  });

  final String userId;
  final NotificationRepository repository;
  final ValueChanged<String> onActivitySelected;
  // TODO(DP-023): App composition supplies this when real profiles exist.
  final ValueChanged<String>? onPersonSelected;
  final DateTime Function()? now;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationsViewModel _viewModel;
  final Set<String> _opening = {};

  @override
  void initState() {
    super.initState();
    _createViewModel();
  }

  void _createViewModel() {
    _viewModel = NotificationsViewModel(
      userId: widget.userId,
      repository: widget.repository,
      now: widget.now,
    );
    _viewModel.load();
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.repository != widget.repository ||
        oldWidget.now != widget.now) {
      _viewModel.dispose();
      _opening.clear();
      _createViewModel();
    }
  }

  Future<void> _open(AppNotification notice) async {
    if (!_opening.add(notice.id)) return;
    final viewModel = _viewModel;
    try {
      final confirmed = await viewModel.markAsRead(notice.id);
      if (!mounted ||
          !identical(viewModel, _viewModel) ||
          !confirmed ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      if (notice.canOpenActivity) {
        widget.onActivitySelected(notice.activityId!);
      } else if (notice.activityId == null && notice.person != null) {
        widget.onPersonSelected?.call(notice.person!.id);
      }
    } finally {
      if (identical(viewModel, _viewModel)) _opening.remove(notice.id);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, child) {
      final colors = Theme.of(context).colorScheme;
      final visible = _viewModel.visibleNotifications;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                for (final category in [
                  null,
                  ...NotificationCategory.values,
                ]) ...[
                  if (category != null) const SizedBox(width: 8),
                  ChoiceChip(
                    key: ValueKey(
                      'notification-filter-${category?.name ?? 'all'}',
                    ),
                    label: Text(notificationFilterLabel(category)),
                    selected: _viewModel.filter == category,
                    onSelected: (_) => _viewModel.selectFilter(category),
                    showCheckmark: false,
                    padding: const EdgeInsets.all(4),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    selectedColor: colors.primary,
                    backgroundColor: colors.surface,
                    labelStyle: TextStyle(
                      color: _viewModel.filter == category
                          ? colors.onPrimary
                          : colors.onSurface,
                    ),
                    side: BorderSide(
                      color: _viewModel.filter == category
                          ? colors.primary
                          : colors.outlineVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_viewModel.isLoading && _viewModel.hasLoaded)
            const LinearProgressIndicator(),
          if (_viewModel.errorMessage != null && _viewModel.hasLoaded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _viewModel.errorMessage!,
                    style: TextStyle(color: colors.error),
                  ),
                  TextButton(
                    onPressed: _viewModel.load,
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildContent(visible)),
        ],
      );
    },
  );

  Widget _buildContent(List<AppNotification> visible) {
    if (!_viewModel.hasLoaded && _viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          semanticsLabel: context.l10n.notifLoading,
        ),
      );
    }
    if (!_viewModel.hasLoaded && _viewModel.errorMessage != null) {
      return _InboxMessage(
        icon: Icons.cloud_off_outlined,
        title: _viewModel.errorMessage!,
        actionLabel: context.l10n.retry,
        onAction: _viewModel.load,
      );
    }
    if (visible.isEmpty) {
      final category = _viewModel.filter;
      final hasOtherNotices = _viewModel.notifications.isNotEmpty;
      final title = switch (category) {
        null => context.l10n.notifEmptyAll,
        NotificationCategory.social => context.l10n.notifEmptySocial,
        NotificationCategory.reminders => context.l10n.notifEmptyReminders,
        NotificationCategory.recommendations =>
          context.l10n.notifEmptyRecommendations,
      };
      final description = switch (category) {
        NotificationCategory.reminders => context.l10n.notifEmptyRemindersHint,
        NotificationCategory.social => context.l10n.notifEmptySocialHint,
        NotificationCategory.recommendations =>
          context.l10n.notifEmptyRecommendationsHint,
        null => context.l10n.notifEmptyAllHint,
      };
      return RefreshIndicator(
        onRefresh: _viewModel.load,
        child: _InboxMessage(
          icon: Icons.notifications_none,
          title: title,
          description: description,
          actionLabel: hasOtherNotices ? context.l10n.notifSeeAll : null,
          onAction: hasOtherNotices
              ? () => _viewModel.selectFilter(null)
              : null,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _viewModel.load,
      child: ListView.builder(
        key: PageStorageKey(
          'notifications-${widget.userId}-${_viewModel.filter?.name ?? 'all'}',
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final notice = visible[index];
          final label = notificationDayLabel(
            notice.receivedAt,
            _viewModel.today,
          );
          final showHeading =
              index == 0 ||
              label !=
                  notificationDayLabel(
                    visible[index - 1].receivedAt,
                    _viewModel.today,
                  );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHeading)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: Semantics(
                      header: true,
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                NotificationCard(
                  key: ValueKey('notification-${notice.id}'),
                  notification: notice,
                  onOpen: () => _open(notice),
                  onRespond: (accept) =>
                      _viewModel.respond(notice.id, accept: accept),
                  profileAvailable: widget.onPersonSelected != null,
                  reading: _viewModel.isReading(notice.id),
                  responding:
                      notice.requestId != null &&
                      _viewModel.isResponding(notice.requestId!),
                  error: _viewModel.errorFor(notice.id),
                  enabled: !_viewModel.isLoading,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InboxMessage extends StatelessWidget {
  const _InboxMessage({
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (description != null) ...[
                const SizedBox(height: 12),
                Text(description!, textAlign: TextAlign.center),
              ],
              if (onAction != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
