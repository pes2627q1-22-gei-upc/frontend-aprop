import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/profile/data/demo_profile_repository.dart';
import 'package:aprop/features/ratings/data/demo_rating_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_settings_repository.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:aprop/features/profile/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../activities/fake_activity_repository.dart';
import 'profile_test_data.dart';

void main() {
  const laia = AppUser(
    id: 'demo-laiasoler',
    firstName: 'Laia',
    lastName: 'Soler',
    username: 'laiasoler',
    email: 'laia@aprop.cat',
    emailVerified: true,
  );

  test('Demo statistics belong only to the example account and plans are resolvable', () async {
    final catalogue = DemoActivityRepository();
    final repository = DemoProfileRepository(activityRepository: catalogue);
    final profile = await repository.getProfile(laia);
    expect(profile.displayName, 'Laia Soler');
    expect(profile.completedPlans, hasLength(3));
    expect(profile.friendCount, 14);
    expect(profile.progress.fraction, .68);
    expect(profile.progress.remainingExperience, 160);
    for (final plan in profile.completedPlans) {
      expect(
        await catalogue.getActivityById(plan.activity.id),
        same(plan.activity),
      );
    }
    final fresh = await repository.getProfile(profileUser);
    expect(fresh.displayName, 'Adam Ziani');
    expect(fresh.completedPlans, isEmpty);
    expect(fresh.friendCount, 0);
    expect(fresh.organizerRating, isNull);
    expect(fresh.progress.experience, 0);
    expect(fresh.progress.nextLevelTarget, isNull);
    expect(fresh.avatarAsset, isNull);
  });

  test(
    'Ownership uses creator IDs, never names or an unknown creator',
    () async {
      final catalogue = FakeActivityRepository()
        ..activities = [
          profileActivity(id: 'own'),
          profileActivity(id: 'someone-else', creatorId: 'user-b'),
          profileActivity(id: 'unknown', creatorId: null),
        ];
      final repository = DemoProfileRepository(activityRepository: catalogue);
      expect(
        (await repository.getProfile(profileUser)).createdActivities
            .map((a) => a.id),
        ['own'],
      );
      catalogue.activities = [
        ...catalogue.activities,
        profileActivity(id: 'new'),
      ];
      expect(
        (await repository.getProfile(profileUser)).createdActivities
            .map((a) => a.id),
        ['own', 'new'],
      );
    },
  );

  test(
    'Organizer rating is the mean of ratings on own community events',
    () async {
      final ratings = DemoRatingRepository();
      final catalogue = FakeActivityRepository()
        ..activities = [
          profileActivity(id: 'a'),
          profileActivity(id: 'b'),
          profileActivity(id: 'other', creatorId: 'user-b'),
        ];
      final repository = DemoProfileRepository(
        activityRepository: catalogue,
        ratingRepository: ratings,
      );
      expect(
        (await repository.getProfile(profileUser)).organizerRating,
        isNull,
      );

      await ratings.rate(userId: 'x', activityId: 'a', score: 5);
      await ratings.rate(userId: 'x', activityId: 'other', score: 1);
      expect((await repository.getProfile(profileUser)).organizerRating, 5);

      await ratings.rate(userId: 'y', activityId: 'b', score: 4);
      expect((await repository.getProfile(profileUser)).organizerRating, 4.5);
    },
  );

  test('Ratings on official events do not count for the organizer', () async {
    final ratings = DemoRatingRepository();
    final official = Activity(
      id: 'official',
      title: 'Concert',
      category: 'Música',
      municipality: 'Girona',
      startsAt: DateTime(2026, 9, 27, 20),
      imageAsset: 'assets/images/teatre_sota_les_estrelles.jpg',
      source: ActivitySource.culturalAgenda,
      creator: const ActivityCreator(
        name: 'Adam Ziani',
        userId: 'user-a',
        isFriend: false,
      ),
    );
    final repository = DemoProfileRepository(
      activityRepository: FakeActivityRepository()..activities = [official],
      ratingRepository: ratings,
    );
    await ratings.rate(userId: 'x', activityId: 'official', score: 5);
    expect((await repository.getProfile(profileUser)).organizerRating, isNull);
  });

  test(
    'Optional details persist per account without changing auth identity',
    () async {
      final repository = DemoProfileRepository(
        activityRepository: DemoActivityRepository(),
      );
      final updated = await repository.updateDetails(
        user: profileUser,
        biography: '  Cinema  ',
        municipality: '  Vic  ',
      );
      expect(updated.biography, 'Cinema');
      expect(updated.municipality, 'Vic');
      expect(updated.username, profileUser.username);
      expect((await repository.getProfile(profileUser)).biography, 'Cinema');
      expect((await repository.getProfile(laia)).biography, isNot('Cinema'));
      final cleared = await repository.updateDetails(
        user: profileUser,
        biography: '',
        municipality: '',
      );
      expect(cleared.municipality, isEmpty);
    },
  );

  test(
    'Empty catalogues do not invent historical plans and failures propagate',
    () async {
      final empty = DemoProfileRepository(
        activityRepository: FakeActivityRepository(),
      );
      expect((await empty.getProfile(laia)).completedPlans, isEmpty);
      final failing = DemoProfileRepository(
        activityRepository: _UnavailableCatalogue(),
      );
      await expectLater(failing.getProfile(laia), throwsStateError);
      await expectLater(
        failing.updateDetails(user: laia, biography: '', municipality: ''),
        throwsStateError,
      );
    },
  );

  test('Profile collections are snapshots and rating/progress display stays coherent', () {
    final plans = [CompletedPlan(activity: profileActivity(), rating: 5)];
    final created = [profileActivity()];
    final profile = UserProfile(
      userId: 'u',
      displayName: 'Name',
      progress: const ProfileProgress(
        level: ProfileLevel.ambassador,
        experience: 1000,
      ),
      completedPlans: plans,
      createdActivities: created,
    );
    plans.clear();
    created.clear();
    expect(profile.completedPlans, hasLength(1));
    expect(() => profile.createdActivities.clear(), throwsUnsupportedError);
    expect(profile.progress.fraction, 1);
    expect(
      () => CompletedPlan(activity: profileActivity(), rating: 0),
      throwsArgumentError,
    );
    expect(
      const ProfileProgress(
        level: ProfileLevel.explorer,
        experience: 600,
        nextLevelTarget: 500,
      ).fraction,
      1,
    );
  });

  test(
    'Language, privacy and delivery changes preserve each other per account',
    () async {
      final repository = DemoProfileSettingsRepository();
      await repository.updateLanguage(userId: 'a', language: 'es');
      await repository.updatePreference(
        userId: 'a',
        preference: ProfilePreference.showMyPlans,
        enabled: true,
      );
      await repository.updateNotificationPreference(
        userId: 'a',
        preference: ProfilePreference.social,
        enabled: false,
      );
      final settings = await repository.getSettings('a');
      expect(settings.language, 'es');
      expect(settings.showMyPlans, isTrue);

      await repository.updateLanguage(userId: 'a', language: 'en');
      expect((await repository.getSettings('a')).showMyPlans, isTrue);
      expect((await repository.getSettings('a')).language, 'en');
      expect(
        (await repository.getNotificationPreferences('a'))
            .valueOf(ProfilePreference.social),
        isFalse,
      );
      expect((await repository.getSettings('b')).language, isNull);
      expect((await repository.getSettings('b')).showMyPlans, isFalse);
      expect(
        (await repository.getNotificationPreferences('b'))
            .valueOf(ProfilePreference.social),
        isTrue,
      );
    },
  );

  test('Preferences default to private and patches preserve other fields and accounts', () async {
    final repository = DemoProfileSettingsRepository();
    expect((await repository.getSettings('a')).showMyPlans, isFalse);
    await repository.updatePreference(
      userId: 'a',
      preference: ProfilePreference.showMyPlans,
      enabled: true,
    );
    final updated = await repository.updateNotificationPreference(
      userId: 'a',
      preference: ProfilePreference.reminders,
      enabled: false,
    );
    expect((await repository.getSettings('a')).showMyPlans, isTrue);
    expect(updated.valueOf(ProfilePreference.reminders), isFalse);
    expect(
      (await repository.getNotificationPreferences('a'))
          .valueOf(ProfilePreference.reminders),
      isFalse,
    );
    expect((await repository.getSettings('b')).showMyPlans, isFalse);
    expect(
      (await repository.getNotificationPreferences('b'))
          .valueOf(ProfilePreference.reminders),
      isTrue,
    );
  });
}

class _UnavailableCatalogue extends FakeActivityRepository {
  @override
  Future<List<Activity>> getActivities() async => throw StateError('Offline');
}
