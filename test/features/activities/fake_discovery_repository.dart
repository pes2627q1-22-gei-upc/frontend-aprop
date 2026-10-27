import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/activity_search_page.dart';
import 'package:aprop/features/activities/models/discovery_feed.dart';
import 'package:aprop/features/activities/repositories/discovery_repository.dart';

class FakeDiscoveryRepository implements DiscoveryRepository {
  DiscoveryFeed feed = DiscoveryFeed(recommended: [], featured: []);
  List<Activity> results = [];
  Future<DiscoveryFeed> Function(String userId)? onFeed;
  Future<List<Activity>> Function(String query)? onSearch;
  Future<ActivitySearchPage> Function(String query, int page)? onPage;
  final pages = <({String query, int page})>[];
  final users = <String>[];
  final queries = <String>[];

  @override
  Future<DiscoveryFeed> getFeed({required String userId}) {
    users.add(userId);
    return onFeed?.call(userId) ?? Future.value(feed);
  }

  @override
  Future<ActivitySearchPage> searchActivitiesPage(
    String query, {
    int page = 0,
  }) async {
    queries.add(query);
    pages.add((query: query, page: page));
    if (onPage != null) return onPage!(query, page);
    final activities = await (onSearch?.call(query) ?? Future.value(results));
    return ActivitySearchPage(
      activities: activities,
      totalCount: activities.length,
    );
  }
}
