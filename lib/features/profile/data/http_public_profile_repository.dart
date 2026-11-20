import '../../../core/network/api_client.dart';
import '../../activities/data/activity_json_mapper.dart';
import '../../activities/models/activity.dart';
import '../models/public_profile.dart';
import '../repositories/public_profile_repository.dart';
import 'profile_json_mapper.dart';

/// `GET /users/{id}` and its lists. The session token goes with every call:
/// the server only reports friendship and visible plans to a known requester.
class HttpPublicProfileRepository implements PublicProfileRepository {
  HttpPublicProfileRepository({
    required this.apiClient,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ApiClient apiClient;
  final DateTime Function() _now;

  @override
  Future<PublicProfile> getPublicProfile(String userId) async {
    final Object? decoded;
    try {
      decoded = await apiClient.getJson(
        'users/${Uri.encodeComponent(userId)}',
        headers: await apiClient.buildHeaders(),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) throw const PublicProfileNotFound();
      rethrow;
    }
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Expected a profile object');
    }
    final id = decoded['id'];
    if (id is! String || id.toLowerCase() != userId.toLowerCase()) {
      throw const FormatException('The profile belongs to another person');
    }
    final isFriend = decoded['is-friend'];
    final plansVisible = decoded['plans-visible'];
    if ((isFriend != null && isFriend is! bool) ||
        (plansVisible != null && plansVisible is! bool)) {
      throw const FormatException('Expected boolean privacy fields');
    }
    return PublicProfile(
      profile: userProfileFromJson(decoded, userId: userId),
      isFriend: isFriend as bool?,
      // Missing means private: never show plans the server did not allow.
      plansVisible: plansVisible == true,
    );
  }

  @override
  Future<List<Activity>> getCreatedActivities(String userId) async {
    final activities = await _activities(
      'users/${Uri.encodeComponent(userId)}/created-events',
    );
    for (final activity in activities) {
      final creatorId = activity.creator?.userId;
      if (activity.source != ActivitySource.community ||
          (creatorId != null &&
              creatorId.toLowerCase() != userId.toLowerCase())) {
        throw const FormatException('Created activity of another person');
      }
    }
    return activities;
  }

  // TODO(DP-063): the API lists sign-ups, not confirmed attendance; «Plans
  // fets» shows the ones that have already started.
  @override
  Future<List<Activity>> getPastPlans(String userId) async {
    final now = _now();
    final activities = await _activities(
      'users/${Uri.encodeComponent(userId)}/events',
    );
    final past = activities.where((a) => !a.startsAt.isAfter(now)).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return List.unmodifiable(past);
  }

  @override
  Future<FriendRequestResult> sendFriendRequest(String userId) async {
    try {
      await apiClient.postJson(
        'users/${Uri.encodeComponent(userId)}/friend-requests',
        headers: await apiClient.buildHeaders(),
      );
      return FriendRequestResult.sent;
    } on ApiException catch (error) {
      if (error.statusCode == 404) throw const PublicProfileNotFound();
      if (error.statusCode != 400) rethrow;
      // TODO(DP-064): every refusal is a 400; only the server's text tells
      // them apart.
      final message = error.message.toLowerCase();
      if (message.contains('pending friend request')) {
        return FriendRequestResult.alreadyPending;
      }
      if (message.contains('already friends')) {
        return FriendRequestResult.alreadyFriends;
      }
      if (message.contains('blocked')) return FriendRequestResult.blocked;
      rethrow;
    }
  }

  Future<List<Activity>> _activities(String path) async {
    final decoded = await apiClient.getJson(
      path,
      headers: await apiClient.buildHeaders(),
    );
    if (decoded is! List<Object?>) {
      throw const FormatException('Expected a list of activities');
    }
    return List.unmodifiable([
      for (final item in decoded)
        if (item is Map<String, Object?>)
          activityFromJson(item)
        else
          throw const FormatException('Expected an activity object'),
    ]);
  }
}
