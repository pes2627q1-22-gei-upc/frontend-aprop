import 'package:flutter/material.dart';

import '../../../../core/widgets/content_image.dart';
import '../../models/activity.dart';

class ActivityImage extends StatelessWidget {
  const ActivityImage({
    super.key,
    required this.activity,
    this.width,
    this.height,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });
  final Activity activity;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  @override
  Widget build(BuildContext context) => ContentImage(
    url: activity.imageUrl,
    asset: activity.imageAsset,
    label: activity.title,
    width: width,
    height: height,
    semanticLabel: semanticLabel,
    excludeFromSemantics: excludeFromSemantics,
  );
}
