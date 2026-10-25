import '../../../core/network/api_client.dart';
import '../models/activity.dart';
import '../models/new_activity.dart';
import '../repositories/activity_repository.dart';
import 'activity_json_mapper.dart';

/// Implementació d'[ActivityRepository] connectada al backend de Render
/// (`/events` i `/categories`).
class HttpActivityRepository implements ActivityRepository {
  HttpActivityRepository({required this.apiClient, this.defaultPageSize = 50});

  final ApiClient apiClient;
  final int defaultPageSize;

  @override
  Future<List<Activity>> getActivities({
    int pageNum = 1,
    int? pageSize,
    int? filterCategory,
    String? filterRegion,
    DateTime? startAfter,
    DateTime? startBefore,
    bool? filterFree,
    bool? filterOfficial,
    String? filterModality,
  }) async {
    final query = <String, String>{
      'pageNum': '$pageNum',
      'pageSize': '${pageSize ?? defaultPageSize}',
      if (filterCategory != null) 'filterCategory': '$filterCategory',
      if (filterRegion != null && filterRegion.isNotEmpty)
        'filterRegion': filterRegion,
      if (startAfter != null)
        'startAfter': startAfter.toUtc().toIso8601String(),
      if (startBefore != null)
        'startBefore': startBefore.toUtc().toIso8601String(),
      if (filterFree != null) 'filterFree': '$filterFree',
      if (filterOfficial != null) 'filterOfficial': '$filterOfficial',
      if (filterModality != null && filterModality.isNotEmpty)
        'filterModality': filterModality,
    };

    final decoded = await apiClient.getJson('events', queryParameters: query);
    final rawList = switch (decoded) {
      final List<Object?> list => list,
      {'events': final List<Object?> list} => list,
      _ => const <Object?>[],
    };

    final activities = <Activity>[
      for (final item in rawList)
        if (item is Map<String, Object?>) activityFromJson(item),
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return List.unmodifiable(activities);
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    if (int.tryParse(id) == null) return null;

    final response = await apiClient.get('events/$id');
    if (response.statusCode == 404) return null;
    final decoded = ApiClient.decodeOrThrow(response);
    if (decoded is! Map<String, Object?>) return null;
    return activityFromJson(decoded);
  }

  @override
  Future<Activity> createActivity(NewActivity activity) async {
    final decoded = await apiClient.postJson(
      'events',
      body: newActivityToJson(activity),
    );
    if (decoded is! Map<String, Object?>) {
      throw ApiException('Resposta invàlida en crear l’activitat.');
    }
    final parsed = activityFromJson(decoded);
    return Activity(
      id: parsed.id,
      title: parsed.title.isNotEmpty ? parsed.title : activity.title,
      category: parsed.category != 'Activitat'
          ? parsed.category
          : activity.category,
      municipality: parsed.municipality.isNotEmpty
          ? parsed.municipality
          : activity.municipality,
      startsAt: parsed.startsAt,
      imageAsset: parsed.imageAsset.isNotEmpty
          ? parsed.imageAsset
          : activity.imageAsset,
      source: ActivitySource.community,
      creator: activity.creator,
      description: parsed.description ?? activity.description,
      directions: parsed.directions ?? activity.directions,
      location: parsed.location ?? activity.location,
      price: parsed.price ?? activity.price,
    );
  }

  /// Puja una imatge per a un esdeveniment (`POST /events/{id}/image`).
  Future<String?> uploadEventImage({
    required String eventId,
    required List<int> bytes,
    required String filename,
  }) async {
    final decoded = await apiClient.postMultipart(
      'events/$eventId/image',
      fieldName: 'image',
      bytes: bytes,
      filename: filename,
    );
    if (decoded is Map<String, Object?>) {
      return decoded['image-url'] as String?;
    }
    return null;
  }

  /// Obté la llista de categories del catàleg (`GET /categories`).
  Future<List<({int id, String name})>> getCategories() async {
    final decoded = await apiClient.getJson('categories');
    if (decoded is! List<Object?>) return const [];
    return [
      for (final item in decoded)
        if (item is Map<String, Object?> &&
            item['id'] is num &&
            item['name'] is String)
          (id: (item['id'] as num).toInt(), name: item['name'] as String),
    ];
  }
}
