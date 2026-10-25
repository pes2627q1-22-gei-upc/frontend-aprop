import 'dart:async';

import '../repositories/activity_repository.dart';
import '../repositories/enrollment_repository.dart';

/// In-memory enrollment data, retained across sign-outs until app shutdown.
// TODO(DP-010): Replace with a backend adapter once its contract is agreed.
// TODO(DP-027): the backend has no endpoint to unenroll yet.
class DemoEnrollmentRepository implements EnrollmentRepository {
  DemoEnrollmentRepository({required this.activityRepository});

  final ActivityRepository activityRepository;
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
            if (changedUserId == userId) controller.add(_snapshot(userId));
          },
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.add(_snapshot(userId));
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> enroll({
    required String userId,
    required String activityId,
  }) async {
    if (_isDisposed) throw StateError('Enrollment repository is closed.');
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');
    final activity = await activityRepository.getActivityById(activityId);
    if (_isDisposed) throw StateError('Enrollment repository is closed.');
    if (activity == null) throw StateError('Activity does not exist.');

    final ids = _enrolledByUser.putIfAbsent(userId, () => <String>{});
    if (ids.add(activityId)) _changes.add(userId);
  }

  @override
  Future<void> unenroll({
    required String userId,
    required String activityId,
  }) async {
    if (_isDisposed) throw StateError('Enrollment repository is closed.');
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');

    final removed = _enrolledByUser[userId]?.remove(activityId) ?? false;
    if (removed) _changes.add(userId);
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _changes.close();
  }
}
