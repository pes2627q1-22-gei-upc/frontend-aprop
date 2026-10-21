import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/discovery_feed.dart';
import 'package:aprop/features/activities/repositories/discovery_repository.dart';

class FakeDiscoveryRepository implements DiscoveryRepository {
  DiscoveryFeed feed = DiscoveryFeed(recommended: [], featured: []);
  List<Activity> results = [];
  Future<DiscoveryFeed> Function(String userId)? onFeed;
  Future<List<Activity>> Function(String query)? onSearch;
  final users = <String>[];
  final queries = <String>[];

  @override
  Future<DiscoveryFeed> getFeed({required String userId}) {
    users.add(userId);
    return onFeed?.call(userId) ?? Future.value(feed);
  }

  @override
  Future<List<Activity>> searchActivities(String query) {
    queries.add(query);
    return onSearch?.call(query) ?? Future.value(results);
  }
}
