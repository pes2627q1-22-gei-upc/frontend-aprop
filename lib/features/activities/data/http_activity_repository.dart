import '../../../core/network/api_client.dart';
import '../models/activity.dart';
import '../models/activity_category.dart';
import '../models/activity_filters.dart';
import '../models/activity_page.dart';
import '../models/new_activity.dart';
import '../repositories/activity_category_repository.dart';
import '../repositories/activity_repository.dart';
import 'activity_json_mapper.dart';

/// Implementació d'[ActivityRepository] connectada al backend de Render
/// (`/events` i `/categories`).
class HttpActivityRepository
    implements ActivityRepository, ActivityCategoryRepository {
  HttpActivityRepository({required this.apiClient, this.defaultPageSize = 50});

  final ApiClient apiClient;
  final int defaultPageSize;
  Future<List<({int id, String name})>>? _categoriesRequest;

  @override
  Future<List<Activity>> getActivities({
    int pageNum = 0,
    int? pageSize,
    int? filterCategory,
    String? filterRegion,
    DateTime? startAfter,
    DateTime? startBefore,
    bool? filterFree,
    bool? filterOfficial,
    String? filterModality,
  }) async {
    RangeError.checkNotNegative(pageNum, 'pageNum');
    if ((pageSize ?? defaultPageSize) < 1) {
      throw ArgumentError.value(pageSize, 'pageSize', 'Must be positive');
    }
    final query = <String, String>{
      'pageNum': '$pageNum',
      'pageSize': '${pageSize ?? defaultPageSize}',
      if (filterCategory != null) 'filterCategory': '$filterCategory',
      if (filterRegion != null && filterRegion.isNotEmpty)
        'filterRegion': filterRegion,
      if (startAfter != null) 'startAfter': _civilDate(startAfter),
      if (startBefore != null) 'startBefore': _civilDate(startBefore),
      if (filterFree != null) 'filterFree': '$filterFree',
      if (filterOfficial != null) 'filterOfficial': '$filterOfficial',
      if (filterModality != null && filterModality.isNotEmpty)
        'filterModality': filterModality,
    };

    final decoded = await apiClient.getJson('events', queryParameters: query);
    final rawList = switch (decoded) {
      final List<Object?> list => list,
      {'events': final List<Object?> list} => list,
      _ => throw const FormatException('Expected an event list'),
    };

    final activities = <Activity>[
      for (final item in rawList)
        if (item is Map<String, Object?>)
          activityFromJson(item)
        else
          throw const FormatException('Expected an event object'),
    ];

    return List.unmodifiable(activities);
  }

  @override
  Future<ActivityPage> getActivitiesPage({
    int page = 0,
    int pageSize = 50,
    ActivityFilters? filters,
  }) async {
    RangeError.checkNotNegative(page, 'page');
    if (pageSize < 1) throw RangeError.range(pageSize, 1, null, 'pageSize');
    final selected = filters ?? ActivityFilters();
    final categoryIds = <int>{};
    if (selected.categories.isNotEmpty) {
      final categories = await getCategories();
      for (final label in selected.categories) {
        final matching = categories.where(
          (category) => activityCategoryLabel(category.name) == label,
        );
        if (matching.isEmpty) {
          throw StateError('Selected category is not in the server catalogue');
        }
        categoryIds.addAll(matching.map((category) => category.id));
      }
    }
    // TODO(DP-038): The API accepts a single category. A batch is page N from
    // each selected category, combined as OR. Bound concurrency and commit the
    // whole batch only when every request succeeds. No new endpoint is assumed.
    final queries = categoryIds.isEmpty
        ? <int?>[null]
        : (categoryIds.toList()..sort()).cast<int?>();
    final batches = <List<Activity>>[];
    for (var offset = 0; offset < queries.length; offset += 4) {
      batches.addAll(
        await Future.wait([
          for (final id in queries.skip(offset).take(4))
            getActivities(
              pageNum: page,
              pageSize: pageSize,
              filterCategory: id,
              startAfter: selected.dates?.start,
              startBefore: selected.dates?.end,
            ),
        ]),
      );
    }
    final items = <String, Activity>{
      for (final batch in batches)
        for (final activity in batch) activity.id: activity,
    }.values;
    // TODO(DP-037): GET /events has no total/next-page metadata. A full page
    // may be followed by an empty last request; preserve the server's order.
    return ActivityPage(
      items: items,
      hasMore: batches.any((batch) => batch.length >= pageSize),
    );
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    if (int.tryParse(id) == null) return null;

    final response = await apiClient.get('events/$id');
    if (response.statusCode == 404) return null;
    final decoded = ApiClient.decodeOrThrow(response);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Expected an event object');
    }
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
    return _fromResponse(decoded, activity);
  }

  /// `PUT /events/{id}`: el backend comprova que qui ho demana és qui
  /// l'ha creada i que no és oficial. Sense imatge nova, conserva la d'abans.
  @override
  Future<Activity> updateActivity(String id, NewActivity activity) async {
    final decoded = await apiClient.putJson(
      'events/$id',
      body: newActivityToJson(activity),
    );
    if (decoded is! Map<String, Object?>) {
      throw ApiException('Resposta invàlida en desar l’activitat.');
    }
    return _fromResponse(decoded, activity);
  }

  /// L'activitat que torna el backend, completada amb el que s'ha enviat si
  /// la resposta no ho porta.
  Activity _fromResponse(Map<String, Object?> decoded, NewActivity activity) {
    final parsed = activityFromJson(decoded);
    return Activity(
      id: parsed.id,
      title: parsed.title.isNotEmpty ? parsed.title : activity.title,
      category: parsed.category != 'Activitat'
          ? parsed.category
          : activity.category,
      categories: parsed.category != 'Activitat'
          ? parsed.categories
          : [activity.category],
      municipality: parsed.municipality.isNotEmpty
          ? parsed.municipality
          : activity.municipality,
      startsAt: parsed.startsAt,
      endsAt: parsed.endsAt,
      imageAsset: parsed.imageAsset.isNotEmpty
          ? parsed.imageAsset
          : activity.imageAsset,
      imageUrl: parsed.imageUrl,
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
  Future<List<({int id, String name})>> getCategories() =>
      _categoriesRequest ??= _fetchCategories()
          .then((categories) {
            // TODO(DP-046): An empty catalogue must remain retryable in this session.
            if (categories.isEmpty) _categoriesRequest = null;
            return categories;
          })
          .catchError((Object error) {
            _categoriesRequest = null;
            throw error;
          });

  Future<List<({int id, String name})>> _fetchCategories() async {
    final decoded = await apiClient.getJson('categories');
    if (decoded is! List<Object?>) {
      throw const FormatException('Expected a category list');
    }
    final categories = <({int id, String name})>[];
    for (final item in decoded) {
      if (item case {'id': final int id, 'name': final String name}
          when id > 0) {
        // TODO(DP-046): Ignore unnamed entries, keeping every usable server ID.
        if (activityCategoryLabel(name).trim().isNotEmpty) {
          categories.add((id: id, name: name));
        }
      } else {
        throw const FormatException('Expected a category ID and name');
      }
    }
    return List.unmodifiable(categories);
  }

  @override
  Future<List<String>> getFilterCategories() async {
    final labels = {
      for (final category in await getCategories())
        activityCategoryLabel(category.name),
    }.toList()..sort();
    return List.unmodifiable(labels);
  }

  /// Categories per crear activitats (`GET /categories`): només les de
  /// l'Agenda Cultural (`agenda:categories/…`), ordenades pel nom. Els àmbits
  /// (`agenda:ambits/…`), les que s'han creat escrivint un nom nou i les que
  /// arriben sense nom no s'ofereixen.
  // TODO(DP-018): llista provisional fins que l'equip tanqui les categories.
  @override
  Future<List<ActivityCategory>> getCreationCategories() async {
    final decoded = await apiClient.getJson('categories');
    if (decoded is! List<Object?>) return const [];
    final categories = [
      for (final item in decoded)
        if (item is Map<String, Object?>)
          if (item['name'] case final String name
              when name.startsWith(_categoryPrefix))
            ActivityCategory(value: name, label: activityCategoryLabel(name)),
    ];
    return categories..sort((a, b) => a.label.compareTo(b.label));
  }
}

const _categoryPrefix = 'agenda:categories/';

// The Go parser requires milliseconds without a zone. SQL compares inclusive
// civil dates; converting to UTC would move midnight to the preceding day.
String _civilDate(DateTime date) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-'
      '${two(date.day)}T00:00:00.000';
}
