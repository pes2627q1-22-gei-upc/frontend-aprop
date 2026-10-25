import '../../../core/network/api_client.dart';
import '../models/activity.dart';
import '../models/discovery_feed.dart';
import '../repositories/activity_repository.dart';
import '../repositories/discovery_repository.dart';
import 'activity_json_mapper.dart';

/// Implementació de [DiscoveryRepository] connectada al backend de Render
/// (`GET /events/search` i catàleg d'esdeveniments).
class HttpDiscoveryRepository implements DiscoveryRepository {
  HttpDiscoveryRepository({
    required this.apiClient,
    this.activityRepository,
    this.searchPageSize = 20,
  });

  final ApiClient apiClient;
  final ActivityRepository? activityRepository;
  final int searchPageSize;

  @override
  Future<DiscoveryFeed> getFeed({required String userId}) async {
    final List<Activity> activities;
    if (activityRepository case final repo?) {
      activities = await repo.getActivities();
    } else {
      final decoded = await apiClient.getJson(
        'events',
        queryParameters: {'pageNum': '1', 'pageSize': '$searchPageSize'},
      );
      final rawList = switch (decoded) {
        final List<Object?> list => list,
        {'events': final List<Object?> list} => list,
        _ => const <Object?>[],
      };
      activities = [
        for (final item in rawList)
          if (item is Map<String, Object?>) activityFromJson(item),
      ];
    }

    if (activities.isEmpty) {
      return DiscoveryFeed(recommended: const [], featured: const []);
    }

    final official = activities
        .where((a) => a.source == ActivitySource.culturalAgenda)
        .take(5)
        .toList();
    final community = activities
        .where((a) => a.source == ActivitySource.community)
        .take(5)
        .toList();

    return DiscoveryFeed(
      recommended: official.isNotEmpty ? official : activities.take(5),
      featured: community.isNotEmpty
          ? community
          : activities.skip(official.length).take(5),
    );
  }

  @override
  Future<List<Activity>> searchActivities(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final decoded = await apiClient.getJson(
      'events/search',
      queryParameters: {
        'q': trimmed,
        'pageNum': '1',
        'pageSize': '$searchPageSize',
      },
    );

    final rawEvents = switch (decoded) {
      {'events': final List<Object?> list} => list,
      final List<Object?> list => list,
      _ => const <Object?>[],
    };

    return List.unmodifiable([
      for (final item in rawEvents)
        if (item is Map<String, Object?>) activityFromJson(item),
    ]);
  }
}
