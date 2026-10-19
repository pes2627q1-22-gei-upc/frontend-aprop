import 'package:flutter/material.dart';

import '../view_models/enrollment_view_model.dart';

/// The same enrollment states for compact cards and the detail's primary action.
class EnrollmentAction extends StatelessWidget {
  const EnrollmentAction({
    super.key,
    required this.viewModel,
    required this.activityId,
    required this.activityTitle,
    this.primary = false,
    this.showHelper = false,
  });

  final EnrollmentViewModel viewModel;
  final String activityId;
  final String activityTitle;
  final bool primary;
  final bool showHelper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final enrolled = viewModel.isEnrolled(activityId);
        final saving = viewModel.isEnrolling(activityId);
        final loading =
            viewModel.isLoading ||
            (!viewModel.hasLoaded && viewModel.loadError == null);
        final readFailed = viewModel.loadError != null;
        final error = enrolled
            ? null
            : viewModel.errorFor(activityId) ?? viewModel.loadError;
        final label = enrolled
            ? 'Apuntat'
            : saving
            ? 'Apuntant…'
            : loading
            ? 'Carregant…'
            : readFailed
            ? 'Tornar-ho a provar'
            : 'M’hi apunto';

        final VoidCallback? onPressed = enrolled || saving || loading
            ? null
            : readFailed
            ? viewModel.load
            : () => viewModel.enroll(activityId);
        final content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!enrolled && (saving || loading)) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                  semanticsLabel: saving
                      ? 'Apuntant-te a l’activitat'
                      : 'Consultant els teus plans',
                ),
              ),
              const SizedBox(width: 8),
            ] else if (enrolled) ...[
              const Icon(Icons.check_circle_outline, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label)),
          ],
        );
        final Widget button;
        if (enrolled || !primary) {
          button = OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(144, 48),
              foregroundColor: colors.primary,
              disabledForegroundColor: colors.primary,
              backgroundColor: enrolled
                  ? colors.primary.withValues(alpha: 0.08)
                  : colors.surface,
              side: BorderSide(color: colors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: content,
          );
        } else {
          button = FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size(144, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: content,
          );
        }

        return Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tooltip(
                message: enrolled
                    ? 'Ja t’has apuntat a $activityTitle'
                    : readFailed
                    ? 'Tornar a consultar els teus plans'
                    : 'Apuntar-me a $activityTitle',
                child: primary
                    ? button
                    : Align(alignment: Alignment.centerRight, child: button),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.error,
                  ),
                ),
              ],
              if (showHelper) ...[
                const SizedBox(height: 8),
                Text(
                  enrolled
                      ? 'Aquest pla ja és a la teva agenda.'
                      : 'Afegeix aquest pla a la teva agenda.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
