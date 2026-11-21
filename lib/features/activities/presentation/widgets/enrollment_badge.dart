import 'package:flutter/material.dart';

import '../view_models/enrollment_view_model.dart';
import '../../../../core/l10n/locale_controller.dart';

/// Distintiu «Apuntat»: indica que l'activitat és a l'agenda de l'usuari. No
/// fa res en tocar-lo; per desapuntar-se hi ha el botó de [EnrollmentAction].
class EnrolledBadge extends StatelessWidget {
  const EnrolledBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: colors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                context.l10n.enrollBadge,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [EnrolledBadge] només quan l'usuari està apuntat a [activityId]. Es
/// manté al dia amb les inscripcions compartides.
class EnrollmentStatusBadge extends StatelessWidget {
  const EnrollmentStatusBadge({
    super.key,
    required this.viewModel,
    required this.activityId,
  });

  final EnrollmentViewModel viewModel;
  final String activityId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) => viewModel.isEnrolled(activityId)
          ? const EnrolledBadge()
          : const SizedBox.shrink(),
    );
  }
}

/// Distintiu «Cancel·lada» (#46): qui l'havia creada l'ha cancel·lat.
class CancelledBadge extends StatelessWidget {
  const CancelledBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      key: const ValueKey('activity-cancelled-badge'),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 16, color: colors.onErrorContainer),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.l10n.activityCancelledBadge,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
