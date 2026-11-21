import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import 'settings_group.dart';

/// A confirmed preference. The switch never previews an unconfirmed write.
class SettingsPreferenceTile extends StatelessWidget {
  const SettingsPreferenceTile({
    super.key,
    required this.switchKey,
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.hint,
    this.status,
    this.saving = false,
    this.error,
    this.onRetry,
  });

  final Key switchKey;
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? hint;
  final String? status;
  final bool saving;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SwitchListTile.adaptive(
        key: switchKey,
        secondary: SettingsIcon(icon: icon),
        title: Text(title),
        subtitle: hint == null && !saving && status == null
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hint case final text?) Text(text),
                  if (saving || status != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          saving ? context.l10n.settingsSavingChange : status!,
                        ),
                      ),
                    ),
                ],
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        value: value,
        onChanged: onChanged,
      ),
      if (error case final message?)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              TextButton(
                key: const ValueKey('retry-preference'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: onRetry,
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
    ],
  );
}
