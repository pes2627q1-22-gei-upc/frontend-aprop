import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/profile/models/user_profile.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/profile/models/profile_avatar.dart';
import 'package:aprop/features/profile/models/profile_capabilities.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:aprop/features/profile/repositories/profile_repository.dart';
import 'package:aprop/features/profile/repositories/profile_image_picker.dart';
import 'package:aprop/features/profile/repositories/profile_settings_repository.dart';

import 'profile_test_data.dart';

class FakeProfileImagePicker implements ProfileImagePicker {
  Future<ProfileAvatar?> Function()? onPick;
  Future<bool> Function()? onRecovery;
  int picks = 0;
  int recoveries = 0;
  @override
  Future<ProfileAvatar?> pickAvatar() async {
    picks++;
    return onPick == null ? null : await onPick!();
  }

  @override
  Future<bool> hadInterruptedSelection() async {
    recoveries++;
    return onRecovery == null ? false : await onRecovery!();
  }
}

class FakeProfileRepository implements ProfileRepository {
  ProfileCapabilities sourceCapabilities = ProfileCapabilities.demo;
  @override
  ProfileCapabilities get capabilities => sourceCapabilities;
  UserProfile profile = sampleProfile();
  Future<UserProfile> Function(AppUser user)? onGet;
  Future<UserProfile> Function(
    AppUser user,
    String biography,
    String municipality,
  )?
  onUpdate;
  final users = <String>[];
  final updates =
      <
        ({
          String userId,
          String biography,
          String municipality,
          String? name,
          String? username,
        })
      >[];
  Future<List<Activity>> Function(AppUser)? onCreated;
  final createdUsers = <String>[];
  Future<UserProfile> Function(ProfileAvatar)? onUpload;
  final uploads = <ProfileAvatar>[];

  @override
  Future<List<Activity>> getCreatedActivities(AppUser user) async {
    createdUsers.add(user.id);
    return onCreated == null
        ? profile.createdActivities
        : await onCreated!(user);
  }

  @override
  Future<UserProfile> uploadAvatar({
    required AppUser user,
    required ProfileAvatar avatar,
  }) async {
    uploads.add(avatar);
    return onUpload == null ? profile : await onUpload!(avatar);
  }

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
    String? name,
    String? username,
  }) {
    updates.add((
      userId: user.id,
      biography: biography,
      municipality: municipality,
      name: name,
      username: username,
    ));
    if (onUpdate != null) return onUpdate!(user, biography, municipality);
    profile = profile.withDetails(
      biography: biography,
      municipality: municipality,
      name: name,
      username: username,
    );
    return Future.value(profile);
  }
}

class FakeProfileSettingsRepository implements ProfileSettingsRepository {
  @override
  Set<ProfilePreference> supportedPreferences = {...ProfilePreference.values};
  @override
  bool persistsPreferences = false;
  ProfileSettings settings = const ProfileSettings();
  Future<ProfileSettings> Function(String userId)? onGet;
  Future<ProfileSettings> Function(
    String userId,
    ProfilePreference preference,
    bool enabled,
  )?
  onUpdate;
  final users = <String>[];
  final languages = <String>[];
  Object? languageError;
  Future<void>? Function(String language)? onUpdateLanguage;
  final updates =
      <({String userId, ProfilePreference preference, bool enabled})>[];

  @override
  Future<void> updateLanguage({
    required String userId,
    required String language,
  }) async {
    languages.add(language);
    await onUpdateLanguage?.call(language);
    if (languageError case final error?) throw error;
  }

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
