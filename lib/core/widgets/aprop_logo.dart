import 'package:flutter/material.dart';

import '../l10n/locale_controller.dart';

/// Shared brand asset for the app's light surfaces.
class APropLogo extends StatelessWidget {
  const APropLogo({
    super.key,
    this.height = 80,
    this.alignment = Alignment.center,
  });

  final double height;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => Image.asset(
    // TODO(DP-047): Confirm the transparent brand asset with the team.
    'assets/branding/aprop_logo_transparent.png',
    height: height,
    fit: BoxFit.contain,
    alignment: alignment,
    filterQuality: FilterQuality.high,
    semanticLabel: currentL10n.appTitle,
  );
}
