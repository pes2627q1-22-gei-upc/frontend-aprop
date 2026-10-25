import '../../../core/network/api_client.dart';
import '../../activities/data/activity_json_mapper.dart';
import '../../activities/models/activity.dart';
import '../../auth/models/app_user.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';

/// Implementació de [ProfileRepository] connectada al backend de Render
/// (`GET /users/me`, `PATCH /users/me`, `GET /users/me/created-events`).
class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository({required this.apiClient});

  final ApiClient apiClient;
  final Map<String, String> _localMunicipalities = {};

  @override
  Future<UserProfile> getProfile(AppUser user) async {
    final profileDecoded = await apiClient.getJson('users/me');
    if (profileDecoded is! Map<String, Object?>) {
      throw ApiException('Resposta invàlida en obtenir el perfil.');
    }

    List<Activity> createdActivities = const [];
    try {
      final createdDecoded = await apiClient.getJson('users/me/created-events');
      if (createdDecoded is List<Object?>) {
        createdActivities = [
          for (final item in createdDecoded)
            if (item is Map<String, Object?>) activityFromJson(item),
        ];
      }
    } on ApiException {
      // Si la consulta d'activitats creades falla, es conserva el perfil principal.
    }

    return _profileFromJson(
      profileDecoded,
      fallbackUser: user,
      createdActivities: createdActivities,
    );
  }

  @override
  Future<UserProfile> updateDetails({
    required AppUser user,
    required String biography,
    required String municipality,
  }) async {
    final trimmedBio = biography.trim();
    final trimmedMunicipality = municipality.trim();
    _localMunicipalities[user.id] = trimmedMunicipality;

    final decoded = await apiClient.patchJson(
      'users/me',
      body: <String, Object?>{'biography': trimmedBio},
    );
    if (decoded is! Map<String, Object?>) {
      throw ApiException('Resposta invàlida en actualitzar el perfil.');
    }

    List<Activity> createdActivities = const [];
    try {
      final createdDecoded = await apiClient.getJson('users/me/created-events');
      if (createdDecoded is List<Object?>) {
        createdActivities = [
          for (final item in createdDecoded)
            if (item is Map<String, Object?>) activityFromJson(item),
        ];
      }
    } on ApiException {
      // Es conserva la llista buida si falla la consulta secundària.
    }

    return _profileFromJson(
      decoded,
      fallbackUser: user,
      createdActivities: createdActivities,
    );
  }

  /// Puja la foto de perfil de l'usuari (`POST /users/me/avatar`).
  Future<UserProfile> uploadAvatar({
    required AppUser user,
    required List<int> bytes,
    required String filename,
  }) async {
    final decoded = await apiClient.postMultipart(
      'users/me/avatar',
      fieldName: 'avatar',
      bytes: bytes,
      filename: filename,
    );
    if (decoded is! Map<String, Object?>) {
      throw ApiException('Resposta invàlida en pujar l’avatar.');
    }
    return _profileFromJson(decoded, fallbackUser: user);
  }

  UserProfile _profileFromJson(
    Map<String, Object?> json, {
    required AppUser fallbackUser,
    List<Activity> createdActivities = const [],
  }) {
    final experience =
        (json['experience'] as num?)?.toInt().clamp(0, 999999) ?? 0;
    final rawLevel = (json['level'] as num?)?.toInt();
    final level = _mapLevel(rawLevel, experience);
    final nextTarget = _nextLevelTarget(level, experience);

    final rawRating = (json['reliability'] as num?) ?? (json['rating'] as num?);
    final name = (json['name'] as String?)?.trim();
    final username = (json['username'] as String?)?.trim();
    final biography = (json['biography'] as String?)?.trim() ?? '';
    final municipality =
        (json['municipality'] as String?)?.trim() ??
        _localMunicipalities[fallbackUser.id] ??
        '';
    final profilePicture = (json['profile-picture'] as String?)?.trim();

    return UserProfile(
      userId: fallbackUser.id,
      displayName: (name != null && name.isNotEmpty)
          ? name
          : fallbackUser.fullName,
      username: (username != null && username.isNotEmpty)
          ? username
          : fallbackUser.username,
      biography: biography,
      municipality: municipality,
      avatarAsset:
          (profilePicture != null && profilePicture.startsWith('assets/'))
          ? profilePicture
          : null,
      friendCount: (json['friends-count'] as num?)?.toInt() ?? 0,
      organizerRating: rawRating?.toDouble(),
      progress: ProfileProgress(
        level: level,
        experience: experience,
        nextLevelTarget: nextTarget,
      ),
      completedPlans: const [],
      createdActivities: createdActivities,
    );
  }

  ProfileLevel _mapLevel(int? backendLevel, int experience) {
    if (backendLevel != null) {
      return switch (backendLevel) {
        <= 1 => ProfileLevel.curious,
        2 => ProfileLevel.explorer,
        3 => ProfileLevel.adventurer,
        4 => ProfileLevel.discoverer,
        _ => ProfileLevel.ambassador,
      };
    }
    if (experience >= 1500) return ProfileLevel.ambassador;
    if (experience >= 1000) return ProfileLevel.discoverer;
    if (experience >= 500) return ProfileLevel.adventurer;
    if (experience >= 200) return ProfileLevel.explorer;
    return ProfileLevel.curious;
  }

  int? _nextLevelTarget(ProfileLevel level, int experience) {
    final baseTarget = switch (level) {
      ProfileLevel.curious => 200,
      ProfileLevel.explorer => 500,
      ProfileLevel.adventurer => 1000,
      ProfileLevel.discoverer => 1500,
      ProfileLevel.ambassador => null,
    };
    if (baseTarget == null) return null;
    return experience > baseTarget ? experience : baseTarget;
  }
}
