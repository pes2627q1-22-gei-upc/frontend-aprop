import 'activity.dart';

/// A snapshot of the catalogue selections, separate from enrollment state.
class DiscoveryFeed {
  DiscoveryFeed({
    required Iterable<Activity> recommended,
    required Iterable<Activity> featured,
    this.isPersonalized = false,
  }) : recommended = List.unmodifiable(recommended),
       featured = List.unmodifiable(featured);

  final List<Activity> recommended;
  final List<Activity> featured;

  /// False when interests are unavailable and the repository offers a fallback.
  final bool isPersonalized;

  bool get isEmpty => recommended.isEmpty && featured.isEmpty;
}
