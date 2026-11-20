import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../auth/models/app_user.dart';
import '../../models/profile_avatar.dart';
import '../../models/profile_capabilities.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_image_picker.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/friendship_repository.dart';
import '../../models/received_friend_request.dart';
import '../../models/profile_failure.dart';
import '../../../../core/l10n/locale_controller.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required this.user,
    required this.repository,
    this._imagePicker,
    FriendshipRepository? friendshipRepository,
  }) {
    _friendChanges = friendshipRepository?.watchChanges(user.id).listen((
      change,
    ) {
      if (_isDisposed || change.status != FriendRequestStatus.accepted) return;
      _friendRevision++;
      _refreshPending = true;
      _flushFriendRefresh();
    });
  }
  StreamSubscription<FriendRequestResolution>? _friendChanges;
  bool _refreshPending = false;
  int _friendRevision = 0;

  void _flushFriendRefresh() {
    if (_isDisposed ||
        !_refreshPending ||
        _isLoading ||
        _isLoadingCreated ||
        isSaving) {
      return;
    }
    _refreshPending = false;
    unawaited(load());
  }

  final AppUser user;
  final ProfileRepository repository;
  final ProfileImagePicker? _imagePicker;
  UserProfile? _profile;
  bool _isLoading = false;
  bool _isSavingDetails = false;
  bool _isChangingAvatar = false;
  bool _isLoadingCreated = false;
  bool _hasLoadedCreated = false;
  bool _isDisposed = false;
  bool _checkedRecovery = false;
  int _avatarAction = 0;
  String? _errorMessage;
  String? _saveError;
  String? _createdError;
  String? _avatarError;

  UserProfile? get profile => _profile;
  ProfileCapabilities get capabilities => repository.capabilities;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSavingDetails || _isChangingAvatar;
  bool get isChangingAvatar => _isChangingAvatar;
  bool get canChangeAvatar => capabilities.uploadAvatar && _imagePicker != null;
  bool get isLoadingCreated => _isLoadingCreated;
  bool get hasLoadedCreated => _hasLoadedCreated;
  String? get errorMessage => _errorMessage;
  String? get saveError => _saveError;
  String? get createdError => _createdError;
  String? get avatarError => _avatarError;

  Future<void> load() async {
    if (_isDisposed || _isLoading || _isLoadingCreated || isSaving) return;
    final revision = _friendRevision;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    var received = false;
    try {
      final result = await repository.getProfile(user);
      if (_isDisposed) return;
      if (result.userId != user.id) throw StateError('Profile account changed');
      if (revision != _friendRevision) return;
      _profile = _profile == null
          ? result
          : result.withCreatedActivities(_profile!.createdActivities);
      received = true;
    } catch (_) {
      if (!_isDisposed) {
        _errorMessage = currentL10n.profileLoadError;
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
        _flushFriendRefresh();
      }
    }
    if (received) await loadCreatedActivities();
  }

  Future<void> loadCreatedActivities() async {
    if (_isDisposed || _profile == null || _isLoadingCreated || _isLoading) {
      return;
    }
    _isLoadingCreated = true;
    _createdError = null;
    notifyListeners();
    try {
      final result = await repository.getCreatedActivities(user);
      if (_isDisposed) return;
      _profile = _profile!.withCreatedActivities(result);
      _hasLoadedCreated = true;
    } catch (_) {
      if (!_isDisposed) {
        _createdError = currentL10n.profileCreatedLoadError;
      }
    } finally {
      if (!_isDisposed) {
        _isLoadingCreated = false;
        notifyListeners();
        _flushFriendRefresh();
      }
    }
  }

  void clearSaveError() {
    if (_isDisposed || _saveError == null) return;
    _saveError = null;
    notifyListeners();
  }

  static String? validateBiography(String? value) =>
      utf8.encode(value?.trim() ?? '').length > 500
      ? currentL10n.profileBiographyTooLong
      : null;
  static String? validateMunicipality(String? value) =>
      (value?.trim().length ?? 0) > 80
      ? currentL10n.profileMunicipalityTooLong
      : null;
  static String? validateName(String? value) => (value?.trim().isEmpty ?? true)
      ? currentL10n.profileNameRequired
      : utf8.encode(value!.trim()).length > 100
      ? currentL10n.profileNameTooLong
      : null;
  static String? validateUsername(String? value) =>
      RegExp(r'^[A-Za-z0-9_]{3,30}$').hasMatch(value?.trim() ?? '')
      ? null
      : currentL10n.profileUsernameInvalid;

  Future<bool> saveDetails({
    required String biography,
    required String municipality,
    String? name,
    String? username,
  }) async {
    if (_isDisposed || _isLoading || isSaving || _profile == null) return false;
    _saveError =
        validateBiography(biography) ??
        (capabilities.editMunicipality
            ? validateMunicipality(municipality)
            : null) ??
        (capabilities.editIdentity && name != null
            ? validateName(name)
            : null) ??
        (capabilities.editIdentity && username != null
            ? validateUsername(username)
            : null);
    if (_saveError != null) {
      notifyListeners();
      return false;
    }
    _isSavingDetails = true;
    notifyListeners();
    try {
      final result = await repository.updateDetails(
        user: user,
        biography: biography.trim(),
        municipality: capabilities.editMunicipality ? municipality.trim() : '',
        name: capabilities.editIdentity ? name?.trim() : null,
        username: capabilities.editIdentity ? username?.trim() : null,
      );
      if (_isDisposed) return false;
      if (result.userId != user.id) throw StateError('Profile account changed');
      _profile = result.withCreatedActivities(_profile!.createdActivities);
      return true;
    } catch (error) {
      if (!_isDisposed) {
        _saveError = error == ProfileFailure.usernameInUse
            ? currentL10n.profileUsernameTaken
            : currentL10n.profileSaveError;
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _isSavingDetails = false;
        notifyListeners();
        _flushFriendRefresh();
      }
    }
  }

  Future<bool> changeAvatar() async {
    if (_isDisposed ||
        !canChangeAvatar ||
        _profile == null ||
        _isLoading ||
        isSaving) {
      return false;
    }
    _avatarAction++;
    _isChangingAvatar = true;
    _avatarError = null;
    notifyListeners();
    try {
      final selected = await _imagePicker!.pickAvatar();
      if (_isDisposed || selected == null) return false;
      final result = await repository.uploadAvatar(
        user: user,
        avatar: selected,
      );
      if (_isDisposed) return false;
      if (result.userId != user.id) throw StateError('Profile account changed');
      _profile = result.withCreatedActivities(_profile!.createdActivities);
      return true;
    } on AvatarSelectionException catch (error) {
      if (!_isDisposed) {
        _avatarError = switch (error.problem) {
          AvatarProblem.tooBig => currentL10n.avatarTooBig,
          AvatarProblem.unreadableName => currentL10n.avatarNameUnreadable,
          AvatarProblem.wrongFormat => currentL10n.avatarWrongFormat,
        };
      }
      return false;
    } catch (_) {
      if (!_isDisposed) {
        _avatarError = currentL10n.profileAvatarError;
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _isChangingAvatar = false;
        notifyListeners();
        _flushFriendRefresh();
      }
    }
  }

  Future<void> checkInterruptedAvatarSelection() async {
    if (_isDisposed || !canChangeAvatar || _checkedRecovery) return;
    _checkedRecovery = true;
    final action = _avatarAction;
    try {
      final interrupted = await _imagePicker!.hadInterruptedSelection();
      if (!_isDisposed && action == _avatarAction && interrupted) {
        _avatarError = currentL10n.profileAvatarInterrupted;
        notifyListeners();
        _flushFriendRefresh();
      }
    } catch (_) {
      // Recovery failure must not upload a stale file or block the profile.
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_friendChanges?.cancel());
    super.dispose();
  }
}
