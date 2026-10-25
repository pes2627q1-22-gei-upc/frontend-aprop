import 'package:flutter/foundation.dart';

import '../../../auth/models/app_user.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';

/// Account-scoped state owned by MainShell and reused by the edit panel.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required this.user, required this.repository});

  final AppUser user;
  final ProfileRepository repository;
  UserProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _saveError;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get saveError => _saveError;

  Future<void> load() async {
    if (_isDisposed || _isLoading || _isSaving) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getProfile(user);
      if (!_isDisposed) _profile = result;
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
  }

  void clearSaveError() {
    if (_isDisposed || _saveError == null) return;
    _saveError = null;
    notifyListeners();
  }

  static String? validateBiography(String? value) =>
      (value?.trim().length ?? 0) > 200
      ? 'Escriu com a màxim 200 caràcters.'
      : null;
  static String? validateMunicipality(String? value) =>
      (value?.trim().length ?? 0) > 80
      ? 'Escriu com a màxim 80 caràcters.'
      : null;

  Future<bool> saveDetails({
    required String biography,
    required String municipality,
  }) async {
    if (_isDisposed || _isLoading || _isSaving || _profile == null) {
      return false;
    }
    _saveError =
        validateBiography(biography) ?? validateMunicipality(municipality);
    if (_saveError != null) {
      notifyListeners();
      return false;
    }
    _isSaving = true;
    notifyListeners();
    try {
      final result = await repository.updateDetails(
        user: user,
        biography: biography.trim(),
        municipality: municipality.trim(),
      );
      if (_isDisposed) return false;
      _profile = result;
      return true;
    } catch (_) {
      if (!_isDisposed) {
        _saveError = 'No hem pogut desar el perfil. Torna-ho a provar.';
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
