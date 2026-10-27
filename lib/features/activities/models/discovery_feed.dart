import 'activity.dart';

enum RecommendationAvailability { available, needsInterests, failed }

/// A snapshot of the catalogue selections, separate from enrollment state.
class DiscoveryFeed {
  DiscoveryFeed({
    required Iterable<Activity> recommended,
    required Iterable<Activity> featured,
    this.isPersonalized = false,
    this.recommendationAvailability = RecommendationAvailability.available,
    this.featuredUnavailable = false,
  }) : recommended = List.unmodifiable(recommended),
       featured = List.unmodifiable(featured);

  final List<Activity> recommended;
  final List<Activity> featured;

  /// False when interests are unavailable and the repository offers a fallback.
  final bool isPersonalized;
  final RecommendationAvailability recommendationAvailability;
  final bool featuredUnavailable;

  bool get recommendationsUnavailable =>
      recommendationAvailability == RecommendationAvailability.failed;
  bool get needsInterests =>
      recommendationAvailability == RecommendationAvailability.needsInterests;
  bool get hasErrors => recommendationsUnavailable || featuredUnavailable;

  bool get isEmpty => recommended.isEmpty && featured.isEmpty;
}
