import 'dart:math' as math;

import '../../activities/repositories/activity_repository.dart';
import '../../ratings/data/demo_rating_repository.dart';
import '../../auth/models/app_user.dart';
import '../models/user_profile.dart';
import '../models/profile_capabilities.dart';
import '../models/profile_avatar.dart';
import '../../activities/models/activity.dart';
import '../repositories/profile_repository.dart';
import 'demo_friendship_repository.dart';
import 'demo_public_profile_repository.dart';

// TODO(DP-032): Replace mockup statistics/attendance with the authenticated API.
class DemoProfileRepository implements ProfileRepository {
  DemoProfileRepository({
    required this.activityRepository,
    this.ratingRepository,
    this.friendshipRepository,
  });

  final ActivityRepository activityRepository;
  final DemoFriendshipRepository? friendshipRepository;

  /// Shared demo ratings; without it `organizerRating` is only the seed.
  final DemoRatingRepository? ratingRepository;

  /// Mean of the scores of the community activities [userId] created (R9);
  /// null if none was rated. Once one is rated it replaces the example seed.
  // TODO(DP-049): HTTP gets `reliability` from the server instead.
  double? _organizerRating(String userId, List<Activity> catalogue) {
    final scores = [
      for (final a in catalogue)
        if (a.source == ActivitySource.community && a.creator?.userId == userId)
          ...?ratingRepository?.scoresFor(a.id),
    ];
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  @override
  ProfileCapabilities get capabilities => ProfileCapabilities.demo;
  final _details = <String, ({String biography, String municipality})>{};

  @override
  Future<UserProfile> getProfile(AppUser user) async {
    final catalogue = await activityRepository.getActivities();
    final isExampleAccount = user.id == 'demo-laiasoler';
    final removedSeedFriends = DemoPublicProfileRepository.friendsOf(null)
        .where(
          (f) =>
              f.id != user.id &&
              friendshipRepository?.confirmedFriendship(user.id, f.id) == false,
        )
        .length;
    final details = _details[user.id];
    const ratings = {'demo-jazz': 5, 'demo-theatre': 5, 'demo-exhibition': 4};
    final completed = isExampleAccount
        ? catalogue
              .where((a) => ratings.containsKey(a.id))
              .map((a) => CompletedPlan(activity: a, rating: ratings[a.id]))
        : const <CompletedPlan>[];
    return UserProfile(
      userId: user.id,
      displayName: user.fullName,
      username: user.username,
      biography:
          details?.biography ??
          (isExampleAccount
              ? "Teatre, concerts a l’aire lliure i alguna exposició."
              : ''),
      municipality: details?.municipality ?? (isExampleAccount ? 'Girona' : ''),
      avatarAsset: isExampleAccount ? 'assets/images/laia_soler.jpg' : null,
      friendCount: math.max(
        0,
        (isExampleAccount ? 14 : 0) +
            (friendshipRepository?.acceptedCount(user.id) ?? 0) -
            removedSeedFriends,
      ),
      organizerRating:
          _organizerRating(user.id, catalogue) ??
          (isExampleAccount ? 4.7 : null),
      progress: isExampleAccount
          ? const ProfileProgress(
              level: ProfileLevel.explorer,
              experience: 340,
              nextLevelTarget: 500,
            )
          : const ProfileProgress(level: ProfileLevel.curious, experience: 0),
      completedPlans: completed,
      // Names are not identifiers: two people can have the same display name.
      createdActivities: catalogue.where((a) => a.creator?.userId == user.id),
    );
  }

  @override
  Future<List<Activity>> getCreatedActivities(AppUser user) async =>
      (await getProfile(user)).createdActivities;

  @override
  Future<UserProfile> uploadAvatar({
    required AppUser user,
    required ProfileAvatar avatar,
  }) async => throw UnsupportedError(
    'Avatar upload is not available in the demo source',
  );

  @override
  Future<UserProfile> updateDetails({
    required AppUser user,
    required String biography,
    required String municipality,
    String? name,
    String? username,
  }) async {
    final profile = await getProfile(user);
    final updated = profile.withDetails(
      biography: biography.trim(),
      municipality: municipality.trim(),
    );
    _details[user.id] = (
      biography: updated.biography,
      municipality: updated.municipality,
    );
    return updated;
  }
}
