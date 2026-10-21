import '../models/activity.dart';
import '../models/discovery_feed.dart';

/// Client-facing operations; this contract does not prescribe HTTP endpoints.
abstract interface class DiscoveryRepository {
  /// Returns the account's selections, or empty sections when none exist.
  /// Throws on a data-access failure; a failure must not become an empty feed.
  Future<DiscoveryFeed> getFeed({required String userId});

  /// Returns matching activities, or an empty list for no matches/blank input.
  /// Throws on a data-access failure. Matching/ranking belongs to the adapter.
  Future<List<Activity>> searchActivities(String query);
}
