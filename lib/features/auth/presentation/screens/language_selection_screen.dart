import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/widgets/aprop_logo.dart';

/// First-launch language picker shown before login/registration when no
/// language preference is stored on the device yet.
// TODO(DP-079): No mockup exists for this screen; uses the auth layout and
// previews the chosen language live before confirming with Continue.
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key, required this.controller});

  final LocaleController controller;

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  bool _isSaving = false;

  Future<void> _confirm() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.controller.setLocale(widget.controller.locale);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final selectedCode = widget.controller.locale.languageCode;
                  final options = [
                    ('ca', context.l10n.languageNameCa),
                    ('es', context.l10n.languageNameEs),
                    ('en', context.l10n.languageNameEn),
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const APropLogo(height: 96),
                      const SizedBox(height: 24),
                      Icon(Icons.language, size: 32, color: colors.primary),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.languagePickerTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.languagePickerSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      for (final (code, label) in options) ...[
                        _LanguageOptionCard(
                          code: code,
                          label: label,
                          selected: selectedCode == code,
                          enabled: !_isSaving,
                          onTap: () =>
                              widget.controller.previewLocale(Locale(code)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const ValueKey('language-picker-continue'),
                        onPressed: _isSaving ? null : _confirm,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : Text(context.l10n.languagePickerContinue),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.code,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      hint: selected ? context.l10n.languagePickerSelectedSemantics : null,
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.08)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('language-option-$code'),
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ExcludeSemantics(
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
