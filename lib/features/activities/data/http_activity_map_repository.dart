import '../models/activity_start.dart';

import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../models/activity.dart';
import '../models/geo_bounds.dart';
import '../repositories/activity_map_repository.dart';
import 'activity_json_mapper.dart';

/// Activitats del mapa d'Inici des del backend: `GET /events/map` amb la zona
/// visible i `GET /events/{id}` per a la fitxa que s'obre des del mapa.
class HttpActivityMapRepository implements ActivityMapRepository {
  HttpActivityMapRepository({
    Uri? baseUrl,
    Future<String?> Function()? idToken,
    http.Client? client,
    Duration timeout = ApiConfig.connectTimeout,
    ApiClient? apiClient,
  }) : _apiClient =
           apiClient ??
           ApiClient(
             baseUrl: baseUrl,
             idToken: idToken,
             client: client,
             timeout: timeout,
           );

  final ApiClient _apiClient;

  @override
  Future<List<Activity>> getActivitiesInArea(GeoBounds area) async {
    final decoded = await _apiClient.getJson(
      'events/map',
      queryParameters: {
        'minLat': '${area.southWest.latitude}',
        'maxLat': '${area.northEast.latitude}',
        'minLng': '${area.southWest.longitude}',
        'maxLng': '${area.northEast.longitude}',
      },
    );
    final events = decoded as List<Object?>? ?? const [];
    final now = activityClock();
    return [
      for (final event in events)
        if (event is Map<String, Object?>)
          if (activityFromJson(event) case final a
              when !activityHasEnded(a, now))
            a,
    ];
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    // Els ID del backend són números: un altre ID no hi pot existir.
    if (int.tryParse(id) == null) return null;

    final response = await _apiClient.get('events/$id');
    if (response.statusCode == 404) return null;
    final decoded = ApiClient.decodeOrThrow(response);
    if (decoded is! Map<String, Object?>) return null;
    return activityFromJson(decoded);
  }
}
