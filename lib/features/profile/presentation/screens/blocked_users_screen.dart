import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/blocked_user.dart';
import '../../repositories/user_blocking_repository.dart';
import '../view_models/blocked_users_view_model.dart';
import '../widgets/user_row.dart';
import '../widgets/user_block_confirmation.dart';

// TODO(DP-077): management is personal; unblocking never restores friendship.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({
    super.key,
    required this.userId,
    required this.repository,
    required this.onUserSelected,
  });
  final String userId;
  final UserBlockingRepository repository;
  final ValueChanged<String> onUserSelected;
  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late BlockedUsersViewModel _model;
  bool _confirming = false;
  BlockedUsersViewModel _create() => BlockedUsersViewModel(
    userId: widget.userId,
    repository: widget.repository,
  )..load();
  @override
  void initState() {
    super.initState();
    _model = _create();
  }

  @override
  void didUpdateWidget(covariant BlockedUsersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.repository != widget.repository) {
      _model.dispose();
      _model = _create();
      _confirming = false;
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _unblock(BlockedUser row) async {
    final model = _model;
    if (_confirming ||
        model.isUnblocking(row.user.id) ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    _confirming = true;
    final confirm = await confirmUserBlock(
      context,
      name: row.user.displayName,
      block: false,
    );
    if (!mounted || !identical(model, _model)) return;
    _confirming = false;
    if (!confirm) return;
    final success = await model.unblock(row.user.id);
    if (!mounted ||
        !identical(model, _model) ||
        !success ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.userUnblockSuccess(row.user.displayName)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.settingsBlockedUsers),
      leading: IconButton(
        tooltip: context.l10n.goBack,
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        final users = _model.users;
        return RefreshIndicator(
          onRefresh: _model.load,
          child: ListView(
            key: PageStorageKey('blocked-users-${widget.userId}'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (_model.isLoading)
                LinearProgressIndicator(
                  semanticsLabel: context.l10n.blockedLoading,
                ),
              if (_model.errorMessage case final error?)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(error, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _model.load,
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  ),
                ),
              if (users != null &&
                  users.isEmpty &&
                  !_model.isLoading &&
                  _model.errorMessage == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Column(
                    children: [
                      const Icon(Icons.block, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.blockedEmptyTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.blockedEmptyMessage,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              for (final row in users ?? const <BlockedUser>[])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UserRow(
                        key: ValueKey('blocked-user-${row.user.id}'),
                        user: row.user,
                        onTap: () {
                          if (ModalRoute.of(context)?.isCurrent ?? true) {
                            widget.onUserSelected(row.user.id);
                          }
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          key: ValueKey('unblock-user-${row.user.id}'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed:
                              _model.isLoading ||
                                  _model.isUnblocking(row.user.id)
                              ? null
                              : () => _unblock(row),
                          icon: _model.isUnblocking(row.user.id)
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_open_outlined),
                          label: Text(
                            _model.isUnblocking(row.user.id)
                                ? context.l10n.userUnblocking
                                : context.l10n.userUnblock,
                            semanticsLabel: context.l10n.userUnblockFrom(
                              row.user.displayName,
                            ),
                          ),
                        ),
                      ),
                      if (_model.actionError(row.user.id) case final error?)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
