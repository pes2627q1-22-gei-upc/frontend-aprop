import 'dart:async';

import 'package:aprop/features/activities/repositories/enrollment_repository.dart';

class FakeEnrollmentRepository implements EnrollmentRepository {
  final Map<String, Set<String>> _idsByUser = {};
  final Map<String, StreamController<Set<String>>> _changes = {};
  final List<String> enrolledRequests = [];
  final List<String> watchedUsers = [];
  Future<void> Function(String userId, String activityId)? onEnroll;
  bool failReads = false;

  StreamController<Set<String>> _controller(String userId) => _changes
      .putIfAbsent(userId, () => StreamController<Set<String>>.broadcast());

  @override
  Stream<Set<String>> watchEnrolledActivityIds(String userId) {
    watchedUsers.add(userId);
    late final StreamController<Set<String>> controller;
    StreamSubscription<Set<String>>? subscription;
    controller = StreamController<Set<String>>(
      onListen: () {
        subscription = _controller(userId).stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        if (failReads) {
          controller.addError(StateError('Offline'));
        } else {
          controller.add(Set.unmodifiable(_idsByUser[userId] ?? <String>{}));
        }
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  void emit(String userId, Set<String> ids) {
    _idsByUser[userId] = Set.of(ids);
    _controller(userId).add(Set.unmodifiable(ids));
  }

  void emitError(String userId) =>
      _controller(userId).addError(StateError('Connection lost'));

  @override
  Future<void> enroll({
    required String userId,
    required String activityId,
  }) async {
    enrolledRequests.add('$userId/$activityId');
    await onEnroll?.call(userId, activityId);
    emit(userId, {...?_idsByUser[userId], activityId});
  }

  Future<void> dispose() async {
    await Future.wait(_changes.values.map((controller) => controller.close()));
  }
}
