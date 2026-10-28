import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/data/demo_discovery_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/discovery_feed.dart';
import 'package:aprop/features/activities/models/new_activity.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_activity_repository.dart';

void main() {
  late DemoActivityRepository catalogue;
  late DemoDiscoveryRepository repository;
  setUp(() {
    catalogue = DemoActivityRepository();
    repository = DemoDiscoveryRepository(activityRepository: catalogue);
  });

  test(
    'Feed reuses the mockup catalogue objects without claiming interests',
    () async {
      final feed = await repository.getFeed(userId: 'user');
      expect(feed.recommended.single.id, 'demo-exhibition');
      expect(feed.featured.single.id, 'demo-theatre');
      expect(feed.isPersonalized, isFalse);
      expect(
        feed.recommended.single,
        same(await catalogue.getActivityById('demo-exhibition')),
      );
      expect(() => feed.recommended.clear(), throwsUnsupportedError);
      expect(() => feed.featured.clear(), throwsUnsupportedError);
    },
  );

  test(
    'The feed snapshots source lists and missing selections stay empty',
    () async {
      final activities = await catalogue.getActivities();
      final feed = DiscoveryFeed(recommended: activities, featured: []);
      final mutable = [...activities];
      final snapshot = DiscoveryFeed(recommended: mutable, featured: mutable);
      mutable.clear();
      expect(snapshot.recommended.length, feed.recommended.length);
      final empty = await DemoDiscoveryRepository(
        activityRepository: FakeActivityRepository(),
      ).getFeed(userId: 'user');
      expect(empty.isEmpty, isTrue);
    },
  );

  test(
    'Search folds accents and case, trims whitespace and requires every term',
    () async {
      expect(
        (await repository.searchActivitiesPage('  MUSICA   barceLONA '))
            .activities
            .single
            .id,
        'demo-jazz',
      );
      expect(
        (await repository.searchActivitiesPage('exposicions girona'))
            .activities
            .single
            .id,
        'demo-exhibition',
      );
      expect(
        (await repository.searchActivitiesPage('exposicions tarragona'))
            .activities,
        isEmpty,
      );
      expect(
        (await repository.searchActivitiesPage('EXPOSICIO\u0301')).activities,
        isNotEmpty,
      );
      final results = (await repository.searchActivitiesPage('teatre'))
          .activities;
      expect(results.single.id, 'demo-theatre');
      expect(() => results.clear(), throwsUnsupportedError);
    },
  );

  test(
    'Blank input never reads the catalogue and no matches is not an error',
    () async {
      final fake = FakeActivityRepository();
      expect(
        (await DemoDiscoveryRepository(activityRepository: fake)
                .searchActivitiesPage(' \n\t '))
            .activities,
        isEmpty,
      );
      expect(fake.listRequests, 0);
      expect(
        (await repository.searchActivitiesPage('inexistent')).activities,
        isEmpty,
      );
    },
  );

  test(
    'Search reads the shared catalogue again after an activity is created',
    () async {
      expect(
        (await repository.searchActivitiesPage('castellers vic')).activities,
        isEmpty,
      );
      final created = await catalogue.createActivity(
        NewActivity(
          title: 'Castellers a Vic',
          description: 'Una diada',
          category: 'Teatre',
          startsAt: DateTime(2026, 12, 1),
          municipality: 'Vic',
          imageAsset: 'assets/images/teatre_sota_les_estrelles.jpg',
          creator: const ActivityCreator(name: 'Pol', isFriend: false),
        ),
      );
      expect(
        (await repository.searchActivitiesPage('castellers vic'))
            .activities
            .single,
        same(created),
      );
    },
  );

  test(
    'Catalogue failures propagate instead of becoming empty results',
    () async {
      final failing = DemoDiscoveryRepository(
        activityRepository: _UnavailableCatalogue(),
      );
      await expectLater(failing.getFeed(userId: 'user'), throwsStateError);
      await expectLater(
        failing.searchActivitiesPage('teatre'),
        throwsStateError,
      );
    },
  );
}

class _UnavailableCatalogue extends FakeActivityRepository {
  @override
  Future<List<Activity>> getActivities() async => throw StateError('Offline');
}
