import '../../activities/repositories/activity_repository.dart';
import '../../auth/models/app_user.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';

// TODO(DP-032): Replace mockup statistics/attendance with the authenticated API.
class DemoProfileRepository implements ProfileRepository {
  DemoProfileRepository({required this.activityRepository});

  final ActivityRepository activityRepository;
  final _details = <String, ({String biography, String municipality})>{};

  @override
  Future<UserProfile> getProfile(AppUser user) async {
    final catalogue = await activityRepository.getActivities();
    final isExampleAccount = user.id == 'demo-laiasoler';
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
      friendCount: isExampleAccount ? 14 : 0,
      organizerRating: isExampleAccount ? 4.7 : null,
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
  Future<UserProfile> updateDetails({
    required AppUser user,
    required String biography,
    required String municipality,
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
