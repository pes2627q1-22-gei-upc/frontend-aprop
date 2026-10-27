import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../auth/models/app_user.dart';
import '../../models/profile_avatar.dart';
import '../../models/profile_capabilities.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_image_picker.dart';
import '../../repositories/profile_repository.dart';
import '../../models/profile_failure.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required this.user,
    required this.repository,
    this._imagePicker,
  });
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    var received = false;
    try {
      final result = await repository.getProfile(user);
      if (_isDisposed) return;
      if (result.userId != user.id) throw StateError('Profile account changed');
      _profile = _profile == null
          ? result
          : result.withCreatedActivities(_profile!.createdActivities);
      received = true;
    } catch (_) {
      if (!_isDisposed) {
        _errorMessage = 'No hem pogut carregar el perfil. Torna-ho a provar.';
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
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
        _createdError = 'No hem pogut carregar les activitats creades.';
      }
    } finally {
      if (!_isDisposed) {
        _isLoadingCreated = false;
        notifyListeners();
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
      ? 'La biografia és massa llarga. Prova de fer-la més curta.'
      : null;
  static String? validateMunicipality(String? value) =>
      (value?.trim().length ?? 0) > 80
      ? 'Escriu com a màxim 80 caràcters.'
      : null;
  static String? validateName(String? value) => (value?.trim().isEmpty ?? true)
      ? 'Escriu el teu nom.'
      : utf8.encode(value!.trim()).length > 100
      ? 'El nom és massa llarg.'
      : null;
  static String? validateUsername(String? value) =>
      RegExp(r'^[A-Za-z0-9_]{3,30}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Fes servir entre 3 i 30 lletres, números o guions baixos.';

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
            ? 'El nom d’usuari ja està ocupat. Tria’n un altre.'
            : 'No hem pogut desar el perfil. Torna-ho a provar.';
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _isSavingDetails = false;
        notifyListeners();
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
      if (!_isDisposed) _avatarError = error.message;
      return false;
    } catch (_) {
      if (!_isDisposed) {
        _avatarError = 'No hem pogut canviar la foto. Torna-ho a provar.';
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _isChangingAvatar = false;
        notifyListeners();
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
        _avatarError =
            'S’ha interromput una selecció de foto. Torna-la a triar.';
        notifyListeners();
      }
    } catch (_) {
      // Recovery failure must not upload a stale file or block the profile.
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
