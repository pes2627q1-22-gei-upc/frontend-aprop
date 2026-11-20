import '../../activities/models/activity.dart';
import '../models/public_profile.dart';

/// Reads other people's profiles. Each call throws on failure; an error must
/// never turn into an empty list.
abstract interface class PublicProfileRepository {
  /// Throws [PublicProfileNotFound] if the person does not exist.
  Future<PublicProfile> getPublicProfile(String userId);

  Future<List<Activity>> getCreatedActivities(String userId);

  /// Plans the person already went to. Call it only when
  /// [PublicProfile.plansVisible] is true.
  Future<List<Activity>> getPastPlans(String userId);
}

class PublicProfileNotFound implements Exception {
  const PublicProfileNotFound();
}
