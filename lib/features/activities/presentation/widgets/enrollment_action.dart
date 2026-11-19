import 'package:flutter/material.dart';

import '../view_models/enrollment_view_model.dart';
import 'enrollment_badge.dart';
import '../../../../core/l10n/locale_controller.dart';

/// The same enrollment states for compact cards and the detail's primary action.
///
/// The button says what it does («M’hi apunto» or «Desapunta’m»); being
/// enrolled is shown apart, with [EnrolledBadge]. Unenrolling does not ask:
/// the plan goes at once and «Desfer» brings it back for a few seconds, so an
/// accidental tap is easy to fix.
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
            ? context.l10n.enrollLeaving
            : enrolled
            ? context.l10n.enrollLeave
            : saving
            ? context.l10n.enrollSigningUp
            : loading
            ? context.l10n.enrollLoading
            : readFailed
            ? context.l10n.retry
            : context.l10n.enrollSignUp;

        final VoidCallback? onPressed = saving || leaving || loading
            ? null
            : enrolled
            // Unenrolling needs the current plans: after a read failure the
            // confirmed state stays visible but cannot be changed.
            ? (readFailed ? null : () => _unenrollWithUndo(context))
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
                      ? context.l10n.enrollLeavingSemantics
                      : saving
                      ? context.l10n.enrollSigningUpSemantics
                      : context.l10n.enrollCheckingSemantics,
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

        // The cards open the activity when tapped anywhere: taps on this
        // area, even on a disabled button or around it, must not do that.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: () {},
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Només per al lector de pantalla: un globus visible en passar
                // per sobre del botó molestava.
                Semantics(
                  tooltip: enrolled
                      ? context.l10n.enrollLeaveTooltip(activityTitle)
                      : readFailed
                      ? context.l10n.enrollRecheckTooltip
                      : context.l10n.enrollSignUpTooltip(activityTitle),
                  child: primary
                      ? button
                      // A les targetes, el distintiu al costat del botó; amb
                      // poc espai o text gran, el botó baixa a la línia següent.
                      : Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (enrolled) const EnrolledBadge(),
                            button,
                          ],
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
                        ? context.l10n.enrollHelperEnrolled
                        : context.l10n.enrollHelperNot,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _unenrollWithUndo(BuildContext context) {
    viewModel.unenrollLater(activityId);
    // TODO(DP-027): text i durada sense mockup.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.enrollLeftSnack(activityTitle)),
          // It starts counting once it has slid in: it ends a little before
          // the removal is sent, so «Desfer» never shows when it no longer
          // works.
          duration: unenrollUndoDelay - const Duration(milliseconds: 750),
          // With an action the bar would stay until closed; it has to go
          // when «Desfer» is no longer possible.
          persist: false,
          action: SnackBarAction(
            label: context.l10n.enrollUndo,
            onPressed: () => viewModel.undoUnenroll(activityId),
          ),
        ),
      );
  }
}
