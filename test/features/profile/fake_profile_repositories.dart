import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/profile/models/user_profile.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:aprop/features/profile/repositories/profile_repository.dart';
import 'package:aprop/features/profile/repositories/profile_settings_repository.dart';

import 'profile_test_data.dart';

class FakeProfileRepository implements ProfileRepository {
  UserProfile profile = sampleProfile();
  Future<UserProfile> Function(AppUser user)? onGet;
  Future<UserProfile> Function(
    AppUser user,
    String biography,
    String municipality,
  )?
  onUpdate;
  final users = <String>[];
  final updates = <({String userId, String biography, String municipality})>[];

  @override
  Future<UserProfile> getProfile(AppUser user) {
    users.add(user.id);
    return onGet?.call(user) ?? Future.value(profile);
  }

  @override
  Future<UserProfile> updateDetails({
    required AppUser user,
    required String biography,
    required String municipality,
  }) {
    updates.add((
      userId: user.id,
      biography: biography,
      municipality: municipality,
    ));
    if (onUpdate != null) return onUpdate!(user, biography, municipality);
    profile = profile.withDetails(
      biography: biography,
      municipality: municipality,
    );
    return Future.value(profile);
  }
}

class FakeProfileSettingsRepository implements ProfileSettingsRepository {
  ProfileSettings settings = const ProfileSettings();
  Future<ProfileSettings> Function(String userId)? onGet;
  Future<ProfileSettings> Function(
    String userId,
    ProfilePreference preference,
    bool enabled,
  )?
  onUpdate;
  final users = <String>[];
  final updates =
      <({String userId, ProfilePreference preference, bool enabled})>[];

  @override
  Future<ProfileSettings> getSettings(String userId) {
    users.add(userId);
    return onGet?.call(userId) ?? Future.value(settings);
  }

  @override
  Future<ProfileSettings> updatePreference({
    required String userId,
    required ProfilePreference preference,
    required bool enabled,
  }) {
    updates.add((userId: userId, preference: preference, enabled: enabled));
    if (onUpdate != null) return onUpdate!(userId, preference, enabled);
    settings = settings.withPreference(preference, enabled);
    return Future.value(settings);
  }
}
