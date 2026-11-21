import 'package:flutter/widgets.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/profile_settings.dart';
import '../../repositories/profile_settings_repository.dart';

class ProfileSettingsViewModel extends ChangeNotifier {
  ProfileSettingsViewModel({
    required this.userId,
    required this.repository,
    required this.onSignOut,
    this.onDeleteAccount,
    this.localeController,
  });

  final LocaleController? localeController;
  final String userId;
  final ProfileSettingsRepository repository;
  final Future<void> Function() onSignOut;

  /// Esborra el compte i tanca la sessió (#10). Sense, l'opció és pendent.
  final Future<void> Function()? onDeleteAccount;
  ProfileSettings? _settings;
  bool _isLoading = false;
  bool _isSigningOut = false;
  bool _isDeletingAccount = false;
  bool _isDisposed = false;
  int _languageWrites = 0;
  ProfilePreference? _savingPreference;
  String? _errorMessage;
  String? _actionError;
  String? _preferenceError;
  ({ProfilePreference preference, bool enabled})? _failedPreferenceChange;

  ProfileSettings? get settings => _settings;
  bool supports(ProfilePreference preference) =>
      repository.supportedPreferences.contains(preference);
  bool get persistsPreferences => repository.persistsPreferences;
  bool get hasLocaleController => localeController != null;
  bool get isLoading => _isLoading;
  bool get isSigningOut => _isSigningOut;
  bool get canDeleteAccount => onDeleteAccount != null;
  bool get isDeletingAccount => _isDeletingAccount;
  bool get isBusy =>
      _savingPreference != null ||
      _isSigningOut ||
      _isDeletingAccount ||
      _languageWrites > 0;
  ProfilePreference? get savingPreference => _savingPreference;
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;
  String? get preferenceError => _preferenceError;
  ProfilePreference? get failedPreference =>
      _failedPreferenceChange?.preference;
  bool get canRetryPreference =>
      _failedPreferenceChange != null &&
      canUpdatePreference(_failedPreferenceChange!.preference);

  bool canUpdatePreference(ProfilePreference preference) =>
      !_isDisposed &&
      !_isLoading &&
      !isBusy &&
      _settings != null &&
      supports(preference);

  Future<void> load() async {
    if (_isDisposed || _isLoading || isBusy) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getSettings(userId);
      if (!_isDisposed) {
        _settings = result;
        _preferenceError = null;
        _failedPreferenceChange = null;
      }
    } catch (_) {
      if (!_isDisposed) {
        _errorMessage = currentL10n.settingsLoadError;
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
    if (!canUpdatePreference(preference) ||
        _settings!.valueOf(preference) == enabled) {
      return;
    }
    _savingPreference = preference;
    _actionError = null;
    _preferenceError = null;
    _failedPreferenceChange = null;
    notifyListeners();
    try {
      final result = await repository.updatePreference(
        userId: userId,
        preference: preference,
        enabled: enabled,
      );
      if (result.valueOf(preference) != enabled) {
        throw StateError('The requested preference was not confirmed');
      }
      if (!_isDisposed) _settings = result;
    } catch (_) {
      if (!_isDisposed) {
        _preferenceError = currentL10n.settingsSaveError;
        _failedPreferenceChange = (preference: preference, enabled: enabled);
      }
    } finally {
      if (!_isDisposed) {
        _savingPreference = null;
        notifyListeners();
      }
    }
  }

  /// Repeats the failed intent, without inverting the last confirmed value.
  Future<void> retryPreference() async {
    final change = _failedPreferenceChange;
    if (change == null || !canRetryPreference) return;
    await updatePreference(change.preference, change.enabled);
  }

  /// Applies the language to the whole app at once (and stores it locally),
  /// then tells the account. A failed sync keeps the new language.
  int _languageRequest = 0;

  Future<void> changeLanguage(Locale locale) async {
    final controller = localeController;
    if (_isDisposed ||
        controller == null ||
        _savingPreference != null ||
        _isSigningOut ||
        _isDeletingAccount) {
      return;
    }
    final request = ++_languageRequest;
    _languageWrites++;
    _actionError = null;
    notifyListeners();
    try {
      await controller.setLocale(locale);
      String? error;
      try {
        await repository.updateLanguage(
          userId: userId,
          language: locale.languageCode,
        );
      } catch (_) {
        error = currentL10n.settingsLanguageSyncError;
      }
      // A newer change owns the result; an older one must not overwrite it.
      if (!_isDisposed && request == _languageRequest) _actionError = error;
    } finally {
      _languageWrites--;
      if (!_isDisposed) notifyListeners();
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
        _actionError = currentL10n.settingsSignOutError;
      }
    } finally {
      if (!_isDisposed) {
        _isSigningOut = false;
        notifyListeners();
      }
    }
  }

  /// Només es crida després de la confirmació del diàleg. Si va bé, la
  /// sessió es tanca i AuthGate mostra l'inici de sessió; si falla, el compte
  /// es conserva i es pot tornar a provar.
  Future<void> deleteAccount() async {
    final delete = onDeleteAccount;
    if (_isDisposed || isBusy || delete == null) return;
    _isDeletingAccount = true;
    _actionError = null;
    notifyListeners();
    try {
      await delete();
    } catch (_) {
      if (!_isDisposed) {
        _actionError = currentL10n.settingsDeleteAccountError;
      }
    } finally {
      if (!_isDisposed) {
        _isDeletingAccount = false;
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
