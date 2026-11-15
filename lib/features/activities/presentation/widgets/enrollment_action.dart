import 'package:flutter/material.dart';

import '../view_models/enrollment_view_model.dart';
import 'enrollment_badge.dart';

/// The same enrollment states for compact cards and the detail's primary action.
///
/// The button says what it does («M’hi apunto» or «Desapunta’m»); being
/// enrolled is shown apart, with [EnrolledBadge]. Unenrolling asks for
/// confirmation, so an accidental tap does not remove the plan.
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
        final leaving = viewModel.isUnenrolling(activityId);
        final loading =
            viewModel.isLoading ||
            (!viewModel.hasLoaded && viewModel.loadError == null);
        final readFailed = viewModel.loadError != null;
        final error =
            viewModel.errorFor(activityId) ??
            (enrolled ? null : viewModel.loadError);
        final label = leaving
            ? 'Desapuntant…'
            : enrolled
            ? 'Desapunta’m'
            : saving
            ? 'Apuntant…'
            : loading
            ? 'Carregant…'
            : readFailed
            ? 'Tornar-ho a provar'
            : 'M’hi apunto';

        final VoidCallback? onPressed = saving || leaving || loading
            ? null
            : enrolled
            // Unenrolling needs the current plans: after a read failure the
            // confirmed state stays visible but cannot be changed.
            ? (readFailed ? null : () => _confirmUnenroll(context))
            : readFailed
            ? viewModel.load
            : () => viewModel.enroll(activityId);
        final content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leaving || (!enrolled && (saving || loading))) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                  semanticsLabel: leaving
                      ? 'Desapuntant-te de l’activitat'
                      : saving
                      ? 'Apuntant-te a l’activitat'
                      : 'Consultant els teus plans',
                ),
              ),
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
              backgroundColor: colors.surface,
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
              // Només per al lector de pantalla: un globus visible en passar
              // per sobre del botó molestava.
              Semantics(
                tooltip: enrolled
                    ? 'Desapuntar-me de $activityTitle'
                    : readFailed
                    ? 'Tornar a consultar els teus plans'
                    : 'Apuntar-me a $activityTitle',
                child: primary
                    ? button
                    // A les targetes, el distintiu al costat del botó; amb
                    // poc espai o text gran, el botó baixa a la línia següent.
                    : Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [if (enrolled) const EnrolledBadge(), button],
                      ),
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

  Future<void> _confirmUnenroll(BuildContext context) async {
    // TODO(DP-027): text i disseny del diàleg sense mockup.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vols desapuntar-te?'),
        content: Text(
          'Treurem «$activityTitle» de la teva agenda. Hi podràs tornar a '
          'apuntar quan vulguis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Mantén el pla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desapunta’m'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await viewModel.unenroll(activityId);
  }
}
