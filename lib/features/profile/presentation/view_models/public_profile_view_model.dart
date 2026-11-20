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
  FriendshipAction? _friendship;
  String? _friendRequestError;

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

  /// The friend button (#160); null hides it (no session, or unknown).
  FriendshipAction? get friendship => _friendship;

  /// Why the last request could not be sent; the button allows a retry.
  String? get friendRequestError => _friendRequestError;

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
      _friendship = switch ((result.isFriend, _friendship)) {
        (true, _) => FriendshipAction.friends,
        // The profile does not say whether a request is pending: keep what
        // this screen already knows.
        (false, final known?) when known != FriendshipAction.friends => known,
        (false, _) => FriendshipAction.add,
        (null, _) => null,
      };
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

  // TODO(DP-064): the profile cannot say that a request is pending or that
  // someone is blocked; the button learns it when the server refuses.
  Future<void> sendFriendRequest() async {
    if (_isDisposed || _friendship != FriendshipAction.add) return;
    _friendship = FriendshipAction.sending;
    _friendRequestError = null;
    notifyListeners();
    try {
      final result = await repository.sendFriendRequest(userId);
      if (_isDisposed) return;
      _friendship = switch (result) {
        FriendRequestResult.sent ||
        FriendRequestResult.alreadyPending => FriendshipAction.requestSent,
        FriendRequestResult.alreadyFriends => FriendshipAction.friends,
        FriendRequestResult.blocked => FriendshipAction.unavailable,
      };
    } catch (_) {
      if (_isDisposed) return;
      _friendship = FriendshipAction.add;
      _friendRequestError = currentL10n.friendRequestError;
    } finally {
      if (!_isDisposed) notifyListeners();
    }
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

/// What the friend button shows and allows.
enum FriendshipAction {
  /// «Afegeix com a amic».
  add,
  sending,

  /// «Sol·licitud enviada», disabled.
  requestSent,

  /// «Amics», disabled.
  friends,

  /// A block between both: no button.
  unavailable,
}

class _ListState {
  List<Activity>? items;
  bool isLoading = false;
  String? error;
}
