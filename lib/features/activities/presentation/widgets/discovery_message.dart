import 'package:flutter/material.dart';

/// Shared, scrollable by its parent, for discovery/search empty and error states.
class DiscoveryMessage extends StatelessWidget {
  const DiscoveryMessage({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? description;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (description case final text?) ...[
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tornar-ho a provar'),
            ),
          ],
        ],
      ),
    );
  }
}
