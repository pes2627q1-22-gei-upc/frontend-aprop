import '../models/activity.dart';
import '../models/activity_search_page.dart';
import '../models/discovery_feed.dart';
import '../repositories/activity_repository.dart';
import '../repositories/discovery_repository.dart';

/// Uses the shared catalogue, so search can also find newly created activities.
// TODO(DP-024): Replace fixture selections and local matching with agreed APIs.
class DemoDiscoveryRepository implements DiscoveryRepository {
  DemoDiscoveryRepository({
    required this.activityRepository,
    this.pageSize = 20,
  });

  final ActivityRepository activityRepository;
  final int pageSize;

  @override
  Future<DiscoveryFeed> getFeed({required String userId}) async {
    final activities = await activityRepository.getActivities();
    // The approved mockup's examples are curated fixtures, not real interests
    // or a production ranking. Missing examples are simply omitted.
    return DiscoveryFeed(
      recommended: activities.where((a) => a.id == 'demo-exhibition'),
      featured: activities.where((a) => a.id == 'demo-theatre'),
    );
  }

  @override
  Future<ActivitySearchPage> searchActivitiesPage(
    String query, {
    int page = 0,
  }) async {
    if (page < 0 || pageSize < 1) throw ArgumentError('Invalid search page');
    final matches = await _search(query);
    final end = (page + 1) * pageSize;
    return ActivitySearchPage(
      activities: matches.skip(page * pageSize).take(pageSize),
      totalCount: matches.length,
      nextPage: end < matches.length ? page + 1 : null,
    );
  }

  Future<List<Activity>> _search(String query) async {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return const [];
    final terms = normalized.split(' ');
    final activities = await activityRepository.getActivities();
    return List.unmodifiable(
      activities.where((activity) {
        final text = _normalize(
          [
            activity.title,
            activity.category,
            activity.municipality,
            activity.description ?? '',
          ].join(' '),
        );
        return terms.every(text.contains);
      }),
    );
  }

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[àáâäãå]'), 'a')
      .replaceAll(RegExp('[èéêë]'), 'e')
      .replaceAll(RegExp('[ìíîï]'), 'i')
      .replaceAll(RegExp('[òóôöõ]'), 'o')
      .replaceAll(RegExp('[ùúûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll('ñ', 'n')
      .replaceAll(RegExp('[\u0300-\u036f]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
