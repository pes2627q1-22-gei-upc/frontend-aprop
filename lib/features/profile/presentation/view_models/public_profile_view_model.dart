import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../activities/models/activity.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../models/public_profile.dart';
import '../../repositories/public_profile_repository.dart';
import '../../repositories/friendship_repository.dart';
import '../../models/received_friend_request.dart';

/// Another person's profile. Its two lists load separately, so one failing
/// does not hide the other or the header.
class PublicProfileViewModel extends ChangeNotifier {
  PublicProfileViewModel({
    required this.userId,
    required this.repository,
    this.friendshipRepository,
    this.currentUserId,
  }) {
    if (friendshipRepository != null && currentUserId != null) {
      _friendChanges = friendshipRepository!
          .watchChanges(currentUserId!)
          .listen((change) {
            if (_isDisposed || change.request.senderId != userId) return;
            _incoming = null;
            _outgoingState = FriendshipAction.add;
            _friendship = change.status == FriendRequestStatus.accepted
                ? FriendshipAction.friends
                : FriendshipAction.add;
            _friendRequestError = null;
            _revision++;
            _reloadPending = true;
            notifyListeners();
            _flushRefresh();
          });
    }
  }
  final FriendshipRepository? friendshipRepository;
  final String? currentUserId;
  StreamSubscription<FriendRequestResolution>? _friendChanges;
  ReceivedFriendRequest? _incoming;
  int _revision = 0;
  bool _reloadPending = false;

  void _flushRefresh() {
    if (_isDisposed || !_reloadPending || _isLoading) return;
    _reloadPending = false;
    unawaited(load());
  }

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

  /// Why the last friendship action failed; the available actions allow retry.
  String? get friendRequestError => _friendRequestError;

  /// A resolved incoming request is feedback, not an error or a new friendship.
  String? get friendRequestFeedback {
    final account = currentUserId;
    if (account == null ||
        _friendship != FriendshipAction.add ||
        _incoming != null) {
      return null;
    }
    final latest = friendshipRepository
        ?.resolutions(account)
        .reversed
        .where((r) => r.request.senderId == userId)
        .firstOrNull;
    return latest?.status == FriendRequestStatus.rejected
        ? currentL10n.notifRequestDeclined
        : null;
  }

  Future<void> load() async {
    if (_isDisposed ||
        _isLoading ||
        _friendship == FriendshipAction.accepting ||
        _friendship == FriendshipAction.rejecting) {
      return;
    }
    final revision = _revision;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    PublicProfile? result;
    try {
      result = await repository.getPublicProfile(userId);
      if (_isDisposed) return;
      if (revision != _revision) return;
      _profile = result;
      _notFound = false;
      await _loadFriendship(result);
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
        _flushRefresh();
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

  Future<void> _loadFriendship(PublicProfile profile) async {
    final friends = friendshipRepository;
    final account = currentUserId;
    if (profile.isFriend == true ||
        (account != null &&
            friends
                    ?.resolutions(account)
                    .any(
                      (r) =>
                          r.request.senderId == userId &&
                          r.status == FriendRequestStatus.accepted,
                    ) ==
                true)) {
      _friendship = FriendshipAction.friends;
      _incoming = null;
      return;
    }
    if (friends == null || account == null) {
      if (profile.isFriend == false &&
          _friendship != FriendshipAction.requestSent &&
          _friendship != FriendshipAction.unavailable) {
        _friendship = FriendshipAction.add;
      }
      return;
    }
    final revision = _revision;
    _friendship = FriendshipAction.checking;
    _friendRequestError = null;
    notifyListeners();
    try {
      final requests = await friends.getReceivedRequests(account);
      if (_isDisposed || revision != _revision) return;
      _incoming = requests.where((r) => r.senderId == userId).firstOrNull;
      _friendship = _incoming != null
          ? FriendshipAction.incoming
          : _outgoingState;
    } catch (_) {
      if (_isDisposed || revision != _revision) return;
      _friendship = FriendshipAction.retry;
      _friendRequestError = currentL10n.friendStatusError;
    }
  }

  FriendshipAction _outgoingState = FriendshipAction.add;

  /// One entry point for the button; the widget never decides business actions.
  Future<void> performFriendAction() async {
    switch (_friendship) {
      case FriendshipAction.add:
        await sendFriendRequest();
      case FriendshipAction.incoming:
        await acceptFriendRequest();
      case FriendshipAction.retry:
        await load();
      default:
        break;
    }
  }

  Future<void> acceptFriendRequest() => _respondToFriendRequest(accept: true);

  Future<void> rejectFriendRequest() => _respondToFriendRequest(accept: false);

  Future<void> _respondToFriendRequest({required bool accept}) async {
    final request = _incoming;
    final friends = friendshipRepository;
    final account = currentUserId;
    if (_isDisposed ||
        _isLoading ||
        _friendship != FriendshipAction.incoming ||
        request == null ||
        friends == null ||
        account == null) {
      return;
    }
    final revision = _revision;
    _friendship = accept
        ? FriendshipAction.accepting
        : FriendshipAction.rejecting;
    _friendRequestError = null;
    notifyListeners();
    try {
      await friends.respond(
        userId: account,
        requestId: request.id,
        accept: accept,
      );
      // One shared confirmation updates all open profiles and the inbox.
    } catch (_) {
      if (_isDisposed || revision != _revision) return;
      _friendship = FriendshipAction.incoming;
      _friendRequestError = accept
          ? currentL10n.friendAcceptError
          : currentL10n.friendRejectError;
    } finally {
      if (!_isDisposed) notifyListeners();
    }
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
    final revision = _revision;
    _friendship = FriendshipAction.sending;
    _friendRequestError = null;
    notifyListeners();
    try {
      final result = await repository.sendFriendRequest(userId);
      if (_isDisposed || revision != _revision) return;
      _friendship = _outgoingState = switch (result) {
        FriendRequestResult.sent ||
        FriendRequestResult.alreadyPending => FriendshipAction.requestSent,
        FriendRequestResult.alreadyFriends => FriendshipAction.friends,
        FriendRequestResult.blocked => FriendshipAction.unavailable,
      };
    } catch (_) {
      if (_isDisposed || revision != _revision) return;
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
    unawaited(_friendChanges?.cancel());
    super.dispose();
  }
}

/// What the friend button shows and allows.
enum FriendshipAction {
  /// «Afegeix com a amic».
  add,
  checking,
  retry,
  incoming,
  accepting,
  rejecting,
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
