import '../../../core/network/api_client.dart';
import '../../activities/data/activity_json_mapper.dart';
import '../../activities/models/activity.dart';
import '../../auth/models/app_user.dart';
import '../models/profile_avatar.dart';
import '../models/profile_capabilities.dart';
import '../models/profile_failure.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';
import 'profile_api.dart';
import 'profile_json_mapper.dart';

class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository({required this.apiClient})
    : _profiles = ProfileApi(apiClient);
  final ApiClient apiClient;
  final ProfileApi _profiles;

  @override
  ProfileCapabilities get capabilities => ProfileCapabilities.backend;

  @override
  Future<UserProfile> getProfile(AppUser user) async =>
      profileFromJson((await _profiles.own(user.id)).profile, user);

  @override
  Future<List<Activity>> getCreatedActivities(AppUser user) async {
    final session = await _profiles.own(user.id);
    final decoded = await apiClient.getJson(
      'users/me/created-events',
      headers: session.headers,
    );
    if (decoded is! List<Object?>) {
      throw const FormatException('Expected created activities');
    }
    final result = <Activity>[];
    for (final item in decoded) {
      if (item is! Map<String, Object?>) {
        throw const FormatException('Expected an activity object');
      }
      final activity = activityFromJson(item);
      if (activity.source != ActivitySource.community ||
          (activity.creator?.userId != null &&
              activity.creator!.userId != session.profile['id'])) {
        throw const FormatException(
          'Created activity belongs to another account',
        );
      }
      result.add(activity);
    }
    return List.unmodifiable(result);
  }

  @override
  Future<UserProfile> updateDetails({
    required AppUser user,
    required String biography,
    required String municipality,
    String? name,
    String? username,
  }) async {
    if (municipality.isNotEmpty) {
      throw UnsupportedError('Municipality is not stored by this API');
    }
    final session = await _profiles.own(user.id);
    try {
      final decoded = await apiClient.patchJson(
        'users/me',
        headers: session.headers,
        body: {
          'biography': biography.trim(),
          if (name != null) 'name': name.trim(),
          if (username != null) 'username': username.trim(),
        },
      );
      return profileFromJson(validateOwnProfile(decoded, user.id), user);
    } on ApiException catch (error) {
      if (error.statusCode == 409) throw ProfileFailure.usernameInUse;
      rethrow;
    }
  }

  @override
  Future<UserProfile> uploadAvatar({
    required AppUser user,
    required ProfileAvatar avatar,
  }) async {
    final session = await _profiles.own(user.id);
    final Object? decoded;
    try {
      decoded = await apiClient.postMultipart(
        'users/me/avatar',
        headers: session.headers,
        fieldName: 'avatar',
        bytes: avatar.bytes,
        filename: avatar.filename,
        // The server limits the whole request, including multipart headers.
        maximumBodyBytes: ProfileAvatar.maxBytes,
      );
    } on MultipartBodyTooLargeException {
      throw const AvatarSelectionException('Tria una foto de menys de 5 MB.');
    }
    final profile = profileFromJson(validateOwnProfile(decoded, user.id), user);
    if (profile.avatarUrl == null) {
      throw const FormatException('Avatar upload did not return an image URL');
    }
    return profile;
  }
}
