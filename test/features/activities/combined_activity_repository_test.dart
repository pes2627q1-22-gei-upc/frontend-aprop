import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/features/activities/data/combined_activity_repository.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/data/demo_enrollment_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';

import 'fake_activity_map_repository.dart';

void main() {
  late DemoActivityRepository catalogue;
  late FakeActivityMapRepository backend;
  late CombinedActivityRepository repository;

  final concert = Activity(
    id: '12',
    title: 'Concert a la plaça',
    category: 'Música',
    municipality: 'Tàrrega',
    startsAt: DateTime(2026, 11, 7),
    imageAsset: '',
    source: ActivitySource.culturalAgenda,
  );

  setUp(() {
    catalogue = DemoActivityRepository();
    backend = FakeActivityMapRepository()..activities = [concert];
    repository = CombinedActivityRepository(
      catalogue: catalogue,
      backend: backend,
    );
  });

  test('Busca els ID numèrics al backend i la resta al catàleg', () async {
    expect(
      (await repository.getActivityById('12'))?.title,
      'Concert a la plaça',
    );
    expect(
      (await repository.getActivityById('demo-jazz'))?.title,
      'Jazz al parc',
    );
    expect(await repository.getActivityById('99'), isNull);
  });

  test('La llista continua sent la del catàleg', () async {
    expect(
      (await repository.getActivities()).map((activity) => activity.id),
      everyElement(startsWith('demo-')),
    );
  });

  test("Es pot apuntar a una activitat oberta des del mapa", () async {
    // Abans, la inscripció només la buscava al catàleg i fallava.
    final enrollments = DemoEnrollmentRepository(
      activityRepository: repository,
    );
    addTearDown(enrollments.dispose);

    await enrollments.enroll(userId: 'user-a', activityId: '12');

    expect(await enrollments.watchEnrolledActivityIds('user-a').first, {'12'});
  });
}
