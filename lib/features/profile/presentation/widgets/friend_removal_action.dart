import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';

/// Presentation only: the caller rechecks its account and ViewModel on return.
Future<bool> confirmFriendRemoval(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        scrollable: true,
        icon: const Icon(Icons.person_remove_outlined),
        title: Text(context.l10n.friendRemoveTitle),
        content: Text(context.l10n.friendRemoveMessage(name)),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.shareCancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-remove-friend'),
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              minimumSize: const Size(48, 48),
            ),
            child: Text(context.l10n.friendRemove),
          ),
        ],
      ),
    ) ??
    false;

class FriendRemovalAction extends StatelessWidget {
  const FriendRemovalAction({
    super.key,
    required this.name,
    required this.onPressed,
    this.removing = false,
  });
  final String name;
  final VoidCallback? onPressed;
  final bool removing;

  @override
  Widget build(BuildContext context) => removing
      ? SizedBox.square(
          dimension: 48,
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: context.l10n.friendRemoving,
              ),
            ),
          ),
        )
      : IconButton(
          tooltip: context.l10n.friendRemoveFrom(name),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          color: Theme.of(context).colorScheme.error,
          onPressed: onPressed,
          icon: const Icon(Icons.person_remove_outlined),
        );
}
