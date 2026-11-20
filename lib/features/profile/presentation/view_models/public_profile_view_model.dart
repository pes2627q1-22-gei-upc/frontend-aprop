import 'package:flutter/foundation.dart';

import '../../../activities/models/activity.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../models/public_profile.dart';
import '../../repositories/public_profile_repository.dart';

/// Another person's profile. Its two lists load separately, so one failing
/// does not hide the other or the header.
class PublicProfileViewModel extends ChangeNotifier {
  PublicProfileViewModel({required this.userId, required this.repository});

  final String userId;
  final PublicProfileRepository repository;

  PublicProfile? _profile;
  bool _isLoading = false;
  bool _notFound = false;
  String? _errorMessage;
  final _created = _ListState();
  final _plans = _ListState();
  bool _isDisposed = false;

  PublicProfile? get profile => _profile;
  bool get isLoading => _isLoading;

  /// The person does not exist (or deleted their account): no retry.
  bool get notFound => _notFound;
  String? get errorMessage => _errorMessage;

  List<Activity>? get createdActivities => _created.items;
  bool get isLoadingCreated => _created.isLoading;
  String? get createdError => _created.error;

  /// Null while they are private or not loaded yet.
  List<Activity>? get pastPlans => _plans.items;
  bool get isLoadingPlans => _plans.isLoading;
  String? get plansError => _plans.error;

  Future<void> load() async {
    if (_isDisposed || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    PublicProfile? result;
    try {
      result = await repository.getPublicProfile(userId);
      if (_isDisposed) return;
      _profile = result;
      _notFound = false;
    } on PublicProfileNotFound {
      if (_isDisposed) return;
      _profile = null;
      _notFound = true;
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = currentL10n.publicProfileLoadError;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
    if (result == null || _isDisposed) return;
    // Never keep plans from before the person made them private.
    if (!result.plansVisible) _plans.items = null;
    await Future.wait([
      loadCreatedActivities(),
      if (result.plansVisible) loadPastPlans(),
    ]);
  }

  Future<void> loadCreatedActivities() => _loadList(
    _created,
    () => repository.getCreatedActivities(userId),
    () => currentL10n.profileCreatedLoadError,
  );

  Future<void> loadPastPlans() async {
    if (!(_profile?.plansVisible ?? false)) return;
    await _loadList(
      _plans,
      () => repository.getPastPlans(userId),
      () => currentL10n.publicProfilePlansLoadError,
    );
  }

  Future<void> _loadList(
    _ListState state,
    Future<List<Activity>> Function() fetch,
    String Function() errorText,
  ) async {
    if (_isDisposed || _profile == null || state.isLoading) return;
    state
      ..isLoading = true
      ..error = null;
    notifyListeners();
    try {
      final items = await fetch();
      if (_isDisposed) return;
      state.items = items;
    } catch (_) {
      if (_isDisposed) return;
      state.error = errorText();
    } finally {
      if (!_isDisposed) {
        state.isLoading = false;
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

class _ListState {
  List<Activity>? items;
  bool isLoading = false;
  String? error;
}
