import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/profile_settings.dart';
import '../../repositories/profile_settings_repository.dart';
import '../../repositories/user_blocking_repository.dart';

class ProfileSettingsViewModel extends ChangeNotifier {
  ProfileSettingsViewModel({
    required this.userId,
    required this.repository,
    required this.onSignOut,
    this.onDeleteAccount,
    this.localeController,
    this.blockingRepository,
  }) {
    _blockChanges = blockingRepository?.watchBlocks(userId).listen((_) {
      if (!_isDisposed) notifyListeners();
    });
  }

  final UserBlockingRepository? blockingRepository;
  StreamSubscription<void>? _blockChanges;
  bool _loadingBlocks = false;
  String? _blocksError;
  int? get blockedUserCount =>
      blockingRepository?.cachedBlockedUsers(userId)?.length;
  String? get blocksError => _blocksError;

  Future<void> _loadBlocks() async {
    if (_isDisposed || _loadingBlocks || blockingRepository == null) return;
    _loadingBlocks = true;
    _blocksError = null;
    try {
      await blockingRepository!.getBlockedUsers(userId);
    } catch (_) {
      if (!_isDisposed) _blocksError = currentL10n.blockedLoadError;
    } finally {
      if (!_isDisposed) {
        _loadingBlocks = false;
        notifyListeners();
      }
    }
  }

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
  ProfilePreference? _savingPreference;
  String? _errorMessage;
  String? _actionError;

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
      _savingPreference != null || _isSigningOut || _isDeletingAccount;
  ProfilePreference? get savingPreference => _savingPreference;
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;

  Future<void> load() async {
    if (_isDisposed || _isLoading || isBusy) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    unawaited(_loadBlocks());
    try {
      final result = await repository.getSettings(userId);
      if (!_isDisposed) _settings = result;
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
        _actionError = currentL10n.settingsSaveError;
      }
    } finally {
      if (!_isDisposed) {
        _savingPreference = null;
        notifyListeners();
      }
    }
  }

  /// Applies the language to the whole app at once (and stores it locally),
  /// then tells the account. A failed sync keeps the new language.
  int _languageRequest = 0;

  Future<void> changeLanguage(Locale locale) async {
    final controller = localeController;
    if (_isDisposed || controller == null) return;
    final request = ++_languageRequest;
    _actionError = null;
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
    if (_isDisposed || request != _languageRequest) return;
    _actionError = error;
    notifyListeners();
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
    unawaited(_blockChanges?.cancel());
    super.dispose();
  }
}
