import 'dart:async';

import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_enrollment_repository.dart';

void main() {
  late FakeEnrollmentRepository repository;
  late EnrollmentViewModel viewModel;

  setUp(() {
    repository = FakeEnrollmentRepository();
    viewModel = EnrollmentViewModel(userId: 'user-a', repository: repository);
  });

  tearDown(() async {
    viewModel.dispose();
    await repository.dispose();
  });

  Future<void> flushEvents() => Future<void>.delayed(Duration.zero);

  Future<void> load() async {
    await viewModel.load();
    await flushEvents();
  }

  test(
    'Loads the current user snapshot and follows repository changes',
    () async {
      repository.emit('user-a', {'demo-jazz'});
      await load();
      expect(viewModel.hasLoaded, isTrue);
      expect(viewModel.isEnrolled('demo-jazz'), isTrue);
      expect(repository.watchedUsers, ['user-a']);
      repository.emit('user-a', {'demo-theatre'});
      await flushEvents();
      expect(viewModel.isEnrolled('demo-theatre'), isTrue);
      expect(viewModel.isEnrolled('demo-jazz'), isFalse);
      expect(
        () => viewModel.enrolledActivityIds.add('other'),
        throwsUnsupportedError,
      );
    },
  );

  test('Waits for confirmation and prevents duplicate enrollments', () async {
    await load();
    final confirmation = Completer<void>();
    repository.onEnroll = (_, _) => confirmation.future;
    final request = viewModel.enroll('demo-jazz');
    await viewModel.enroll('demo-jazz');
    expect(viewModel.isEnrolling('demo-jazz'), isTrue);
    expect(viewModel.isEnrolled('demo-jazz'), isFalse);
    expect(repository.enrolledRequests, ['user-a/demo-jazz']);
    confirmation.complete();
    await request;
    await flushEvents();
    expect(viewModel.isEnrolled('demo-jazz'), isTrue);
    expect(viewModel.isEnrolling('demo-jazz'), isFalse);
    await viewModel.enroll('demo-jazz');
    expect(repository.enrolledRequests, hasLength(1));
  });

  test('A failed enrollment remains unsaved and can be retried', () async {
    await load();
    repository.onEnroll = (_, _) async => throw StateError('Offline');
    await viewModel.enroll('demo-jazz');
    expect(viewModel.isEnrolled('demo-jazz'), isFalse);
    expect(viewModel.errorFor('demo-jazz'), isNotNull);
    expect(viewModel.isEnrolling('demo-jazz'), isFalse);
    repository.onEnroll = null;
    await viewModel.enroll('demo-jazz');
    expect(viewModel.isEnrolled('demo-jazz'), isTrue);
    expect(viewModel.errorFor('demo-jazz'), isNull);
  });

  test('Different activities can be enrolled independently', () async {
    await load();
    final jazz = Completer<void>();
    repository.onEnroll = (_, id) =>
        id == 'demo-jazz' ? jazz.future : Future.value();
    final pending = viewModel.enroll('demo-jazz');
    await viewModel.enroll('demo-theatre');
    expect(viewModel.isEnrolled('demo-theatre'), isTrue);
    expect(viewModel.isEnrolling('demo-jazz'), isTrue);
    jazz.complete();
    await pending;
    await flushEvents();
    expect(viewModel.enrolledActivityIds, {'demo-jazz', 'demo-theatre'});
  });

  test('An initial read failure blocks writes and supports retry', () async {
    repository.failReads = true;
    await load();
    expect(viewModel.loadError, isNotNull);
    expect(viewModel.hasLoaded, isFalse);
    await viewModel.enroll('demo-jazz');
    expect(repository.enrolledRequests, isEmpty);
    repository.failReads = false;
    await load();
    expect(viewModel.loadError, isNull);
    expect(viewModel.hasLoaded, isTrue);
  });

  test('Read errors retain confirmed plans until refreshed', () async {
    await load();
    await viewModel.enroll('demo-jazz');
    await flushEvents();
    repository.emitError('user-a');
    await flushEvents();
    expect(viewModel.loadError, isNotNull);
    expect(viewModel.isEnrolled('demo-jazz'), isTrue);
    await load();
    expect(viewModel.loadError, isNull);
    expect(viewModel.isEnrolled('demo-jazz'), isTrue);
  });

  test('Unenrolls after confirmation and allows enrolling again', () async {
    repository.emit('user-a', {'demo-jazz'});
    await load();
    final confirmation = Completer<void>();
    repository.onUnenroll = (_, _) => confirmation.future;
    final request = viewModel.unenroll('demo-jazz');
    await viewModel.unenroll('demo-jazz');
    await viewModel.enroll('demo-jazz');
    expect(viewModel.isUnenrolling('demo-jazz'), isTrue);
    expect(viewModel.isEnrolled('demo-jazz'), isTrue);
    expect(repository.unenrolledRequests, ['user-a/demo-jazz']);
    expect(repository.enrolledRequests, isEmpty);
    confirmation.complete();
    await request;
    await flushEvents();
    expect(viewModel.isEnrolled('demo-jazz'), isFalse);
    expect(viewModel.isUnenrolling('demo-jazz'), isFalse);
    await viewModel.enroll('demo-jazz');
    expect(viewModel.isEnrolled('demo-jazz'), isTrue);
  });

  test('A failed unenrollment keeps the plan and can be retried', () async {
    repository.emit('user-a', {'demo-jazz'});
    await load();
    repository.onUnenroll = (_, _) async => throw StateError('Offline');
    await viewModel.unenroll('demo-jazz');
    expect(viewModel.isEnrolled('demo-jazz'), isTrue);
    expect(
      viewModel.errorFor('demo-jazz'),
      'No t’hem pogut desapuntar. Torna-ho a provar.',
    );
    expect(viewModel.isUnenrolling('demo-jazz'), isFalse);
    repository.onUnenroll = null;
    await viewModel.unenroll('demo-jazz');
    await flushEvents();
    expect(viewModel.isEnrolled('demo-jazz'), isFalse);
    expect(viewModel.errorFor('demo-jazz'), isNull);
  });

  test('Only confirmed plans with readable state can be removed', () async {
    await load();
    await viewModel.unenroll('demo-jazz');
    expect(repository.unenrolledRequests, isEmpty);

    repository.emit('user-a', {'demo-jazz'});
    await flushEvents();
    repository.emitError('user-a');
    await flushEvents();
    await viewModel.unenroll('demo-jazz');
    expect(repository.unenrolledRequests, isEmpty);
    expect(viewModel.isEnrolled('demo-jazz'), isTrue);
  });

  test('Other accounts cannot change this user state', () async {
    await load();
    repository.emit('user-b', {'demo-jazz'});
    await flushEvents();
    expect(viewModel.enrolledActivityIds, isEmpty);
  });

  test(
    'Disposal ignores a pending write and late repository updates',
    () async {
      final disposable = EnrollmentViewModel(
        userId: 'user-a',
        repository: repository,
      );
      await disposable.load();
      await flushEvents();
      final confirmation = Completer<void>();
      repository.onEnroll = (_, _) => confirmation.future;
      var notifications = 0;
      disposable.addListener(() => notifications++);
      final pending = disposable.enroll('demo-jazz');
      disposable.dispose();
      confirmation.complete();
      await pending;
      repository.emit('user-a', {'demo-jazz', 'demo-theatre'});
      await flushEvents();
      expect(notifications, 1);
      expect(disposable.enrolledActivityIds, isEmpty);
    },
  );

  group('Unenrolling with «Desfer»', () {
    const shortDelay = Duration(milliseconds: 10);
    Future<void> afterDelay() =>
        Future<void>.delayed(const Duration(milliseconds: 40));

    test('Undo keeps the plan and tells the backend nothing', () async {
      repository.emit('user-a', {'demo-jazz'});
      await load();

      viewModel.unenrollLater('demo-jazz', delay: shortDelay);
      expect(viewModel.isEnrolled('demo-jazz'), isFalse);
      expect(viewModel.enrolledActivityIds, isEmpty);

      viewModel.undoUnenroll('demo-jazz');
      expect(viewModel.isEnrolled('demo-jazz'), isTrue);
      await afterDelay();
      expect(repository.unenrolledRequests, isEmpty);
      expect(viewModel.isEnrolled('demo-jazz'), isTrue);
    });

    test('Joining again before the delay is the same as undoing', () async {
      repository.emit('user-a', {'demo-jazz'});
      await load();

      viewModel.unenrollLater('demo-jazz', delay: shortDelay);
      await viewModel.enroll('demo-jazz');

      expect(viewModel.isEnrolled('demo-jazz'), isTrue);
      await afterDelay();
      expect(repository.enrolledRequests, isEmpty);
      expect(repository.unenrolledRequests, isEmpty);
    });

    test('Unenrolls after the delay; a failure brings the plan back', () async {
      repository.emit('user-a', {'demo-jazz'});
      await load();
      repository.onUnenroll = (_, _) async => throw StateError('Offline');

      viewModel.unenrollLater('demo-jazz', delay: shortDelay);
      await afterDelay();
      expect(viewModel.isEnrolled('demo-jazz'), isTrue);
      expect(viewModel.isUnenrollDeferred('demo-jazz'), isFalse);
      expect(
        viewModel.errorFor('demo-jazz'),
        'No t’hem pogut desapuntar. Torna-ho a provar.',
      );

      repository.onUnenroll = null;
      viewModel.unenrollLater('demo-jazz', delay: shortDelay);
      await afterDelay();
      await flushEvents();
      expect(viewModel.isEnrolled('demo-jazz'), isFalse);
      expect(viewModel.errorFor('demo-jazz'), isNull);
      expect(repository.unenrolledRequests, hasLength(2));
    });

    test('It is too late to undo once the request is sent', () async {
      repository.emit('user-a', {'demo-jazz'});
      await load();
      final confirmation = Completer<void>();
      repository.onUnenroll = (_, _) => confirmation.future;

      viewModel.unenrollLater('demo-jazz', delay: shortDelay);
      await afterDelay();
      viewModel.undoUnenroll('demo-jazz');
      expect(viewModel.isEnrolled('demo-jazz'), isFalse);

      confirmation.complete();
      await flushEvents();
      expect(viewModel.isEnrolled('demo-jazz'), isFalse);
      expect(viewModel.isUnenrollDeferred('demo-jazz'), isFalse);
    });

    test('Closing the screen sends removals still waiting', () async {
      repository.emit('user-b', {'demo-jazz'});
      final closing = EnrollmentViewModel(
        userId: 'user-b',
        repository: repository,
      );
      await closing.load();
      await flushEvents();

      closing.unenrollLater('demo-jazz', delay: const Duration(minutes: 1));
      closing.dispose();
      await flushEvents();

      expect(repository.unenrolledRequests, ['user-b/demo-jazz']);
    });
  });
}
