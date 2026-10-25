import 'dart:async';

import '../../../core/network/api_client.dart';
import '../models/activity.dart';
import '../repositories/enrollment_repository.dart';
import 'activity_json_mapper.dart';

/// Implementació d'[EnrollmentRepository] connectada al backend de Render
/// (`/events/{id}/signup` i `/users/{userId}/events`).
class HttpEnrollmentRepository implements EnrollmentRepository {
  HttpEnrollmentRepository({required this.apiClient});

  final ApiClient apiClient;
  final Map<String, Set<String>> _enrolledByUser = {};
  final StreamController<String> _changes = StreamController.broadcast();
  bool _isDisposed = false;

  Set<String> _snapshot(String userId) =>
      Set.unmodifiable(_enrolledByUser[userId] ?? const <String>{});

  @override
  Stream<Set<String>> watchEnrolledActivityIds(String userId) {
    late final StreamController<Set<String>> controller;
    StreamSubscription<String>? subscription;

    controller = StreamController<Set<String>>(
      onListen: () {
        if (_isDisposed) {
          controller.addError(StateError('Enrollment repository is closed.'));
          controller.close();
          return;
        }
        subscription = _changes.stream.listen(
          (changedUserId) {
            if (changedUserId == userId && !controller.isClosed) {
              controller.add(_snapshot(userId));
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) controller.addError(error, stackTrace);
          },
          onDone: controller.close,
        );

        if (_enrolledByUser.containsKey(userId)) {
          controller.add(_snapshot(userId));
        }

        unawaited(_fetchInitialEnrollments(userId, controller));
      },
      onCancel: () => subscription?.cancel(),
    );

    return controller.stream;
  }

  Future<void> _fetchInitialEnrollments(
    String userId,
    StreamController<Set<String>> controller,
  ) async {
    try {
      final events = await getUserEvents(userId);
      if (_isDisposed || controller.isClosed) return;
      final fetchedIds = <String>{for (final e in events) e.id};
      final existing = _enrolledByUser[userId];
      _enrolledByUser[userId] = fetchedIds;
      if (existing == null || !_sameSet(existing, fetchedIds)) {
        controller.add(_snapshot(userId));
      }
    } catch (error, stackTrace) {
      if (_isDisposed || controller.isClosed) return;
      if (!_enrolledByUser.containsKey(userId)) {
        controller.addError(error, stackTrace);
      }
    }
  }

  bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  Future<void> enroll({
    required String userId,
    required String activityId,
  }) async {
    if (_isDisposed) throw StateError('Enrollment repository is closed.');
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');

    await apiClient.postJson('events/$activityId/signup');
    if (_isDisposed) throw StateError('Enrollment repository is closed.');

    final ids = _enrolledByUser.putIfAbsent(userId, () => <String>{});
    if (ids.add(activityId)) {
      _changes.add(userId);
    }
  }

  @override
  Future<void> unenroll({
    required String userId,
    required String activityId,
  }) async {
    if (_isDisposed) throw StateError('Enrollment repository is closed.');
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');

    await apiClient.deleteJson('events/$activityId/signup');
    if (_isDisposed) throw StateError('Enrollment repository is closed.');

    final removed = _enrolledByUser[userId]?.remove(activityId) ?? false;
    if (removed) {
      _changes.add(userId);
    }
  }

  /// Consulta l'estat d'inscripció i el total d'assistents (`GET /events/{id}/signup`).
  Future<({bool isEnrolled, int enrolledCount})> getEnrollmentStatus(
    String activityId,
  ) async {
    final decoded = await apiClient.getJson('events/$activityId/signup');
    if (decoded is! Map<String, Object?>) {
      throw ApiException('Resposta invàlida en consultar la inscripció.');
    }
    return (
      isEnrolled: decoded['is-enrolled'] as bool? ?? false,
      enrolledCount: (decoded['enrolled-count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Obté l'agenda d'esdeveniments als quals l'usuari està inscrit (`GET /users/{userId}/events`).
  Future<List<Activity>> getUserEvents(
    String userId, {
    String? from,
    String? to,
  }) async {
    final query = <String, String>{
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
    };
    Object? decoded;
    try {
      decoded = await apiClient.getJson(
        'users/$userId/events',
        queryParameters: query.isEmpty ? null : query,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 400 && !ApiClient.isCanonicalUuid(userId)) {
        final uuid = ApiClient.toCanonicalUuid(userId);
        decoded = await apiClient.getJson(
          'users/$uuid/events',
          queryParameters: query.isEmpty ? null : query,
        );
      } else {
        rethrow;
      }
    }
    if (decoded is! List<Object?>) return const [];
    return [
      for (final item in decoded)
        if (item is Map<String, Object?>) activityFromJson(item),
    ];
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _changes.close();
  }
}
