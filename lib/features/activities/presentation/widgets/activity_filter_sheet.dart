import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';

/// Draft content can scroll; confirmation actions stay above the safe area.
class ActivityFilterSheet extends StatelessWidget {
  const ActivityFilterSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.summary,
    required this.onClear,
    required this.onApply,
  });

  final String title;
  final String subtitle;
  final Widget content;
  final Widget summary;
  final VoidCallback onClear;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final compactHeight = MediaQuery.sizeOf(context).height < 700;
    return FractionallySizedBox(
      heightFactor: largeText || compactHeight ? .96 : .82,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!largeText) ...[
                          const SizedBox(height: 4),
                          Text(subtitle, style: theme.textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.actCloseFilter,
                    onPressed: () {
                      if (ModalRoute.of(context)?.isCurrent ?? false) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('activity-filter-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (largeText) ...[
                      Text(subtitle, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                    ],
                    content,
                    if (largeText) ...[
                      const Divider(height: 24),
                      Semantics(liveRegion: true, child: summary),
                    ],
                  ],
                ),
              ),
            ),
            if (!largeText) ...[
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(liveRegion: true, child: summary),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final clear = OutlinedButton(
                    onPressed: onClear,
                    child: Text(context.l10n.actClear),
                  );
                  final apply = FilledButton(
                    onPressed: onApply,
                    child: Text(context.l10n.actApply),
                  );
                  final style = ButtonStyle(
                    minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                  return Theme(
                    data: theme.copyWith(
                      outlinedButtonTheme: OutlinedButtonThemeData(
                        style: style,
                      ),
                      filledButtonTheme: FilledButtonThemeData(style: style),
                    ),
                    child: largeText
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [clear, const SizedBox(height: 8), apply],
                          )
                        : Row(
                            children: [
                              Expanded(child: clear),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: apply),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
