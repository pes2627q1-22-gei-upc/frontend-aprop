import '../models/activity_search_page.dart';
import '../models/discovery_feed.dart';

/// Client-facing operations; this contract does not prescribe HTTP endpoints.
abstract interface class DiscoveryRepository {
  /// Returns the account's selections, or empty sections when none exist.
  /// Throws on a data-access failure; a failure must not become an empty feed.
  Future<DiscoveryFeed> getFeed({required String userId});

  /// Zero-based pages. Blank input returns an empty page without a request.
  /// Failures throw; an empty page is a successfully completed search.
  Future<ActivitySearchPage> searchActivitiesPage(String query, {int page = 0});
}
