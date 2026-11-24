import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';

Future<bool> confirmUserBlock(
  BuildContext context, {
  required String name,
  required bool block,
}) async =>
    await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        scrollable: true,
        icon: Icon(block ? Icons.block : Icons.lock_open_outlined),
        title: Text(
          block
              ? context.l10n.userBlockTitle(name)
              : context.l10n.userUnblockTitle(name),
        ),
        content: Text(
          block
              ? context.l10n.userBlockMessage
              : context.l10n.userUnblockMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(context.l10n.shareCancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-user-block'),
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: block
                  ? Theme.of(context).colorScheme.error
                  : null,
              foregroundColor: block
                  ? Theme.of(context).colorScheme.onError
                  : null,
            ),
            child: Text(
              block ? context.l10n.userBlock : context.l10n.userUnblock,
            ),
          ),
        ],
      ),
    ) ??
    false;
