import 'package:flutter/material.dart';

/// Covers use the image host directly; API authorization headers are not sent.
class ContentImage extends StatelessWidget {
  const ContentImage({
    super.key,
    this.url,
    this.asset,
    required this.label,
    this.placeholderIcon = Icons.image_outlined,
    this.width,
    this.height,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });

  final String? url;
  final String? asset;
  final String label;
  final IconData placeholderIcon;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? provider;
    if (url case final imageUrl? when imageUrl.isNotEmpty) {
      provider = NetworkImage(
        imageUrl,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      );
    } else if (asset?.isNotEmpty ?? false) {
      provider = AssetImage(asset!);
    } else {
      provider = null;
    }
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(child: Icon(placeholderIcon, size: 32)),
      ),
    );
    return ExcludeSemantics(
      excluding: excludeFromSemantics,
      child: Semantics(
        image: true,
        label: semanticLabel ?? label,
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
