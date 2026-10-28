import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/data/demo_enrollment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoEnrollmentRepository repository;
  setUp(() {
    repository = DemoEnrollmentRepository(
      activityRepository: DemoActivityRepository(),
    );
  });
  tearDown(() => repository.dispose());

  test('Enrollment is idempotent and snapshots cannot be mutated', () async {
    await repository.enroll(userId: 'user-a', activityId: 'demo-jazz');
    await repository.enroll(userId: 'user-a', activityId: 'demo-jazz');
    final ids = await repository.watchEnrolledActivityIds('user-a').first;
    expect(ids, {'demo-jazz'});
    expect(() => ids.add('other'), throwsUnsupportedError);
  });

  test('Keeps the enrollment data isolated by account', () async {
    await repository.enroll(userId: 'user-a', activityId: 'demo-jazz');
    expect(await repository.watchEnrolledActivityIds('user-b').first, isEmpty);
    expect(await repository.watchEnrolledActivityIds('user-a').first, {
      'demo-jazz',
    });
  });

  test(
    'Calendar and list subscribers receive the same confirmed changes',
    () async {
      final list = <Set<String>>[];
      final agenda = <Set<String>>[];
      final first = repository
          .watchEnrolledActivityIds('user-a')
          .listen(list.add);
      final second = repository
          .watchEnrolledActivityIds('user-a')
          .listen(agenda.add);
      await Future<void>.delayed(Duration.zero);
      await repository.enroll(userId: 'user-a', activityId: 'demo-theatre');
      await Future<void>.delayed(Duration.zero);
      expect(list, [
        <String>{},
        {'demo-theatre'},
      ]);
      expect(agenda, list);
      await first.cancel();
      await second.cancel();
    },
  );

  test('Unknown activities are rejected without creating a plan', () async {
    await expectLater(
      repository.enroll(userId: 'user-a', activityId: 'missing'),
      throwsStateError,
    );
    expect(await repository.watchEnrolledActivityIds('user-a').first, isEmpty);
  });

  test('Unenrolling removes only that plan and notifies subscribers', () async {
    await repository.enroll(userId: 'user-a', activityId: 'demo-jazz');
    await repository.enroll(userId: 'user-b', activityId: 'demo-jazz');
    final snapshots = <Set<String>>[];
    final subscription = repository
        .watchEnrolledActivityIds('user-a')
        .listen(snapshots.add);
    await Future<void>.delayed(Duration.zero);

    await repository.unenroll(userId: 'user-a', activityId: 'demo-jazz');
    // Repetir-ho no torna a avisar: no hi ha res a treure.
    await repository.unenroll(userId: 'user-a', activityId: 'demo-jazz');
    await Future<void>.delayed(Duration.zero);

    expect(snapshots, [
      {'demo-jazz'},
      <String>{},
    ]);
    expect(await repository.watchEnrolledActivityIds('user-b').first, {
      'demo-jazz',
    });
    await subscription.cancel();
  });
}
