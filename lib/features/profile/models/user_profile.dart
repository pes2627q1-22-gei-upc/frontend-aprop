import '../../activities/models/activity.dart';

enum ProfileLevel { curious, explorer, adventurer, discoverer, ambassador }

/// A confirmed attendance projection, not an enrollment inferred from a date.
class CompletedPlan {
  CompletedPlan({required this.activity, this.rating}) {
    if (rating != null && (rating! < 1 || rating! > 5)) {
      throw ArgumentError.value(rating, 'rating', 'Must be between 1 and 5');
    }
  }

  final Activity activity;
  final int? rating;
}

/// XP thresholds and the current level are supplied by the repository.
class ProfileProgress {
  const ProfileProgress({
    required this.level,
    required this.experience,
    this.nextLevelTarget,
    this.serverLevel,
  }) : assert(experience >= 0),
       assert(nextLevelTarget == null || nextLevelTarget > 0);

  final ProfileLevel? level;
  final int experience;
  final int? nextLevelTarget;
  final int? serverLevel;

  double get fraction {
    if (nextLevelTarget case final target?) {
      return (experience / target).clamp(0, 1).toDouble();
    }
    return level == ProfileLevel.ambassador ? 1 : 0;
  }

  int? get remainingExperience => switch (nextLevelTarget) {
    final target? => (target - experience).clamp(0, target),
    null => null,
  };
}

class UserProfile {
  UserProfile({
    required this.userId,
    required this.displayName,
    required this.progress,
    this.username,
    this.biography = '',
    this.municipality = '',
    this.avatarAsset,
    this.avatarUrl,
    this.planCount,
    this.friendCount = 0,
    this.organizerRating,
    Iterable<CompletedPlan> completedPlans = const [],
    Iterable<Activity> createdActivities = const [],
  }) : completedPlans = List.unmodifiable(completedPlans),
       createdActivities = List.unmodifiable(createdActivities);

  final String userId;
  final String displayName;
  final String? username;
  final String biography;
  final String municipality;
  final String? avatarAsset;
  final String? avatarUrl;
  final int? planCount;
  int get displayedPlanCount => planCount ?? completedPlans.length;
  final int friendCount;

  /// Feedback received as an organizer; not the user's ratings of attended plans.
  final double? organizerRating;
  final ProfileProgress progress;
  final List<CompletedPlan> completedPlans;
  final List<Activity> createdActivities;

  UserProfile withDetails({
    required String biography,
    required String municipality,
    String? name,
    String? username,
  }) {
    return UserProfile(
      userId: userId,
      displayName: name ?? displayName,
      username: username ?? this.username,
      biography: biography,
      municipality: municipality,
      avatarAsset: avatarAsset,
      avatarUrl: avatarUrl,
      planCount: planCount,
      friendCount: friendCount,
      organizerRating: organizerRating,
      progress: progress,
      completedPlans: completedPlans,
      createdActivities: createdActivities,
    );
  }

  UserProfile withCreatedActivities(Iterable<Activity> activities) =>
      UserProfile(
        userId: userId,
        displayName: displayName,
        progress: progress,
        username: username,
        biography: biography,
        municipality: municipality,
        avatarAsset: avatarAsset,
        avatarUrl: avatarUrl,
        planCount: planCount,
        friendCount: friendCount,
        organizerRating: organizerRating,
        completedPlans: completedPlans,
        createdActivities: activities,
      );
}
