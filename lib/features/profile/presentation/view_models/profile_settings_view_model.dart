import 'package:flutter/foundation.dart';

import '../../models/profile_settings.dart';
import '../../repositories/profile_settings_repository.dart';

class ProfileSettingsViewModel extends ChangeNotifier {
  ProfileSettingsViewModel({
    required this.userId,
    required this.repository,
    required this.onSignOut,
  });

  final String userId;
  final ProfileSettingsRepository repository;
  final Future<void> Function() onSignOut;
  ProfileSettings? _settings;
  bool _isLoading = false;
  bool _isSigningOut = false;
  bool _isDisposed = false;
  ProfilePreference? _savingPreference;
  String? _errorMessage;
  String? _actionError;

  ProfileSettings? get settings => _settings;
  bool supports(ProfilePreference preference) =>
      repository.supportedPreferences.contains(preference);
  bool get persistsPreferences => repository.persistsPreferences;
  bool get isLoading => _isLoading;
  bool get isSigningOut => _isSigningOut;
  bool get isBusy => _savingPreference != null || _isSigningOut;
  ProfilePreference? get savingPreference => _savingPreference;
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;

  Future<void> load() async {
    if (_isDisposed || _isLoading || isBusy) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getSettings(userId);
      if (!_isDisposed) _settings = result;
    } catch (_) {
      if (!_isDisposed) {
        _errorMessage =
            'No hem pogut carregar la configuració. Torna-ho a provar.';
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> updatePreference(
    ProfilePreference preference,
    bool enabled,
  ) async {
    if (_isDisposed ||
        _isLoading ||
        isBusy ||
        _settings == null ||
        !supports(preference) ||
        _settings!.valueOf(preference) == enabled) {
      return;
    }
    _savingPreference = preference;
    _actionError = null;
    notifyListeners();
    try {
      final result = await repository.updatePreference(
        userId: userId,
        preference: preference,
        enabled: enabled,
      );
      if (!_isDisposed) _settings = result;
    } catch (_) {
      if (!_isDisposed) {
        _actionError = 'No hem pogut desar el canvi. Torna-ho a provar.';
      }
    } finally {
      if (!_isDisposed) {
        _savingPreference = null;
        notifyListeners();
      }
    }
  }

  Future<void> signOut() async {
    if (_isDisposed || isBusy) return;
    _isSigningOut = true;
    _actionError = null;
    notifyListeners();
    try {
      await onSignOut();
    } catch (_) {
      if (!_isDisposed) {
        _actionError = 'No hem pogut tancar la sessió. Torna-ho a provar.';
      }
    } finally {
      if (!_isDisposed) {
        _isSigningOut = false;
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
