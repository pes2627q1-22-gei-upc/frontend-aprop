import 'package:flutter/material.dart';

import '../../models/activity.dart';

/// Covers use the image host directly; API authorization headers are not sent.
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
  Widget build(BuildContext context) {
    final ImageProvider? provider;
    if (activity.imageUrl case final url? when url.isNotEmpty) {
      provider = NetworkImage(
        url,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      );
    } else if (activity.imageAsset.isNotEmpty) {
      provider = AssetImage(activity.imageAsset);
    } else {
      provider = null;
    }
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SizedBox(
        width: width,
        height: height,
        child: const Center(child: Icon(Icons.image_outlined, size: 32)),
      ),
    );
    return ExcludeSemantics(
      excluding: excludeFromSemantics,
      child: Semantics(
        image: true,
        label: semanticLabel ?? activity.title,
        excludeSemantics: true,
        child: provider == null
            ? placeholder
            : Image(
                image: provider,
                width: width,
                height: height,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                frameBuilder: (context, child, frame, synchronous) =>
                    synchronous || frame != null ? child : placeholder,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}
