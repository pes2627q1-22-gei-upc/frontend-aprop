import '../../../core/network/api_client.dart';
import '../models/activity.dart';
import '../models/activity_search_page.dart';
import '../models/discovery_feed.dart';
import '../repositories/discovery_repository.dart';
import 'activity_json_mapper.dart';

/// Uses the server's selections and ranking; no local stand-in for interests.
class HttpDiscoveryRepository implements DiscoveryRepository {
  HttpDiscoveryRepository({
    required this.apiClient,
    this.searchPageSize = 20,
    this.feedPageSize = 5,
  }) : assert(searchPageSize > 0),
       assert(feedPageSize > 0);

  final ApiClient apiClient;
  final int searchPageSize;
  final int feedPageSize;

  Future<Map<String, String>> _headers() async {
    final headers = Map<String, String>.unmodifiable(
      await apiClient.buildHeaders(),
    );
    if (!RegExp(r'^Bearer \S+$').hasMatch(headers['Authorization'] ?? '')) {
      throw ApiException(
        'Cal iniciar sessió per descobrir activitats.',
        statusCode: 401,
      );
    }
    return headers;
  }

  @override
  Future<DiscoveryFeed> getFeed({required String userId}) async {
    final headers = await _headers();
    final profile = await apiClient.getJson('users/me', headers: headers);
    if (profile is! Map<String, Object?>) {
      throw const FormatException('Expected the authenticated profile');
    }
    final id = profile['id'];
    if (id is! String ||
        !RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')
            .hasMatch(id) ||
        id == '00000000-0000-0000-0000-000000000000') {
      throw const FormatException('Expected the authenticated profile UUID');
    }
    if (userId.isEmpty ||
        (profile['firebase-uid'] != userId &&
            id.toLowerCase() != userId.toLowerCase())) {
      throw ApiException(
        'La sessió ha canviat. Torna a carregar Descobreix.',
        statusCode: 401,
      );
    }
    final sections = await Future.wait([
      _recommendations(headers),
      _featured(headers),
    ]);
    final recommended = sections[0];
    final featured = sections[1];
    return DiscoveryFeed(
      recommended: recommended.activities,
      featured: featured.activities,
      isPersonalized:
          recommended.availability == RecommendationAvailability.available,
      recommendationAvailability: recommended.availability,
      featuredUnavailable:
          featured.availability == RecommendationAvailability.failed,
    );
  }

  Future<_SectionResult> _recommendations(Map<String, String> headers) async {
    try {
      final preferences = await apiClient.getJson(
        'preferences',
        headers: headers,
      );
      if (preferences is! List<Object?>) {
        throw const FormatException('Expected preferences');
      }
      for (final preference in preferences) {
        if (preference is! Map<String, Object?> ||
            preference['category-id'] is! int ||
            (preference['category-id'] as int) < 1 ||
            preference['category-name'] is! String ||
            (preference['category-name'] as String).trim().isEmpty ||
            preference['weight'] is! num ||
            !(preference['weight'] as num).isFinite ||
            (preference['weight'] as num) <= 0) {
          throw const FormatException('Invalid category preference');
        }
      }
      if (preferences.isEmpty) {
        return const _SectionResult(
          [],
          RecommendationAvailability.needsInterests,
        );
      }
      // TODO(DP-041): Backend ranks within a catalogue page and currently returns
      // 500 for missing category weights. Keep its order; expose a real error.
      return _SectionResult(await _selection('events/recommended', headers));
    } catch (error) {
      if (error is ApiException && {401, 403}.contains(error.statusCode)) {
        rethrow;
      }
      return const _SectionResult([], RecommendationAvailability.failed);
    }
  }

  Future<_SectionResult> _featured(Map<String, String> headers) async {
    try {
      return _SectionResult(await _selection('events/popular', headers));
    } catch (error) {
      if (error is ApiException && {401, 403}.contains(error.statusCode)) {
        rethrow;
      }
      return const _SectionResult([], RecommendationAvailability.failed);
    }
  }

  Future<List<Activity>> _selection(
    String path,
    Map<String, String> headers,
  ) async => _activities(
    await apiClient.getJson(
      path,
      headers: headers,
      queryParameters: {'pageNum': '0', 'pageSize': '$feedPageSize'},
    ),
  );

  List<Activity> _activities(Object? decoded) {
    if (decoded is! List<Object?>) {
      throw const FormatException('Expected activities');
    }
    final activities = <String, Activity>{};
    for (final row in decoded) {
      if (row is! Map<String, Object?>) {
        throw const FormatException('Expected an activity');
      }
      final activity = activityFromJson(row);
      activities.putIfAbsent(activity.id, () => activity);
    }
    return List.unmodifiable(activities.values);
  }

  @override
  Future<ActivitySearchPage> searchActivitiesPage(
    String query, {
    int page = 0,
  }) async {
    if (page < 0) throw ArgumentError.value(page, 'page');
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return ActivitySearchPage(activities: [], totalCount: 0);
    }
    final headers = await _headers();
    final decoded = await apiClient.getJson(
      'events/search',
      headers: headers,
      queryParameters: {
        'q': trimmed,
        'pageNum': '$page',
        'pageSize': '$searchPageSize',
      },
    );
    if (decoded is! Map<String, Object?> ||
        decoded['query'] != trimmed ||
        decoded['page-num'] != page ||
        decoded['page-size'] != searchPageSize ||
        decoded['total'] is! int ||
        (decoded['total'] as int) < 0) {
      throw const FormatException('Expected matching search page and total');
    }
    final activities = _activities(decoded['events']);
    final total = decoded['total'] as int;
    if (activities.length > searchPageSize ||
        activities.length > total ||
        (activities.isEmpty && page * searchPageSize < total)) {
      throw const FormatException('Inconsistent search results');
    }
    return ActivitySearchPage(
      activities: activities,
      totalCount: total,
      nextPage: (page + 1) * searchPageSize < total ? page + 1 : null,
    );
  }
}

class _SectionResult {
  const _SectionResult(
    this.activities, [
    this.availability = RecommendationAvailability.available,
  ]);
  final List<Activity> activities;
  final RecommendationAvailability availability;
}
