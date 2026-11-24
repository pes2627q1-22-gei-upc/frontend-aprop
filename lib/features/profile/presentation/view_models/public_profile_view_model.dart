import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../activities/models/activity.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../models/public_profile.dart';
import '../../repositories/public_profile_repository.dart';
import '../../repositories/friendship_repository.dart';
import '../../models/received_friend_request.dart';
import '../../models/friendship_removal.dart';
import '../../models/user_summary.dart';

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
      _blocked = friendshipRepository!.isBlocked(currentUserId!, userId);
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
      _friendRemovals = friendshipRepository!
          .watchRemovals(currentUserId!)
          .listen((change) {
            if (_isDisposed ||
                (change.friendId != userId &&
                    change.friendId != _profile?.profile.userId)) {
              return;
            }
            _friendship = _outgoingState = FriendshipAction.add;
            _incoming = null;
            _friendRequestError = null;
            final previous = _profile;
            if (previous != null) {
              _profile = PublicProfile(
                profile: previous.profile,
                plansVisible: false,
                isFriend: false,
              );
            }
            _plans.items = null;
            _plans.error = null;
            _revision++;
            _reloadPending = true;
            notifyListeners();
            _flushRefresh();
          });
      _blockChanges = friendshipRepository!
          .watchBlocks(currentUserId!)
          .listen((_) => _onBlockChanged());
    }
  }
  final FriendshipRepository? friendshipRepository;
  final String? currentUserId;
  StreamSubscription<FriendRequestResolution>? _friendChanges;
  StreamSubscription<FriendshipRemoval>? _friendRemovals;
  StreamSubscription<void>? _blockChanges;
  bool? _blocked;
  bool _blockBusy = false;
  bool _blockIntent = true;
  String? _blockError;
  bool get isUserBlocked => _blocked == true;
  bool get isManagingBlock => _blockBusy;
  bool get isBlocking => _blockIntent;
  String? get blockError => _blockError;
  bool get canManageBlocks =>
      !_isDisposed &&
      !_isLoading &&
      !_removingFriend &&
      !_blockBusy &&
      friendshipRepository != null &&
      currentUserId != null &&
      _profile != null &&
      _blocked != null;

  void _onBlockChanged() {
    if (_isDisposed) return;
    final next = friendshipRepository!.isBlocked(currentUserId!, userId);
    final previous = _blocked;
    if (previous == next) return;
    _blocked = next;
    if (next == true || previous == true) {
      _incoming = null;
      _outgoingState = FriendshipAction.add;
      _friendship = next == true
          ? FriendshipAction.unavailable
          : FriendshipAction.checking;
      _friendRequestError = null;
      _plans.items = null;
      final person = _profile;
      if (person != null) {
        _profile = PublicProfile(
          profile: person.profile,
          plansVisible: false,
          isFriend: false,
        );
      }
      _revision++;
      _reloadPending = true;
    }
    notifyListeners();
    _flushRefresh();
  }

  Future<bool> setBlocked(bool blocked) async {
    if (!canManageBlocks || blocked == isUserBlocked) return false;
    final person = _profile!.profile;
    _blockBusy = true;
    _blockIntent = blocked;
    _blockError = null;
    notifyListeners();
    try {
      if (blocked) {
        await friendshipRepository!.blockUser(
          userId: currentUserId!,
          target: UserSummary(
            id: person.userId,
            username: person.username ?? person.displayName,
            displayName: person.displayName,
            avatarUrl: person.avatarUrl,
            avatarAsset: person.avatarAsset,
          ),
        );
      } else {
        await friendshipRepository!.unblockUser(
          userId: currentUserId!,
          targetId: person.userId,
        );
      }
      return !_isDisposed;
    } catch (_) {
      if (!_isDisposed) {
        _blockError = blocked
            ? currentL10n.userBlockError
            : currentL10n.userUnblockError;
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _blockBusy = false;
        notifyListeners();
        _flushRefresh();
      }
    }
  }

  bool _removingFriend = false;
  bool get isRemovingFriend => _removingFriend;
  bool get canRemoveFriend =>
      !_isDisposed &&
      !_isLoading &&
      !_removingFriend &&
      !_blockBusy &&
      _friendship == FriendshipAction.friends &&
      friendshipRepository != null &&
      currentUserId != null;
  ReceivedFriendRequest? _incoming;
  int _revision = 0;
  bool _reloadPending = false;

  void _flushRefresh() {
    if (_isDisposed ||
        !_reloadPending ||
        _isLoading ||
        _removingFriend ||
        _blockBusy ||
        _plans.isLoading ||
        _created.isLoading) {
      return;
    }
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
        _blockBusy ||
        _removingFriend ||
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
      if (friendshipRepository != null && currentUserId != null) {
        try {
          await friendshipRepository!.getBlockedUsers(currentUserId!);
          _blocked = friendshipRepository!.isBlocked(currentUserId!, userId);
          _blockError = null;
        } catch (_) {
          if (!_isDisposed) _blockError = currentL10n.blockedLoadError;
        }
      }
      if (_isDisposed || revision != _revision) return;
      result = await repository.getPublicProfile(userId);
      if (_isDisposed) return;
      if (revision != _revision) return;
      if (result.isFriend == true && currentUserId != null) {
        friendshipRepository?.reconcileFriends(currentUserId!, [
          result.profile.userId,
        ]);
      }
      _profile = isUserBlocked
          ? PublicProfile(
              profile: result.profile,
              plansVisible: false,
              isFriend: false,
            )
          : result;
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
    if (result == null || _isDisposed || revision != _revision) return;
    // Never keep plans from before the person made them private.
    if (!(_profile?.plansVisible ?? false)) _plans.items = null;
    await Future.wait([
      loadCreatedActivities(),
      if (_profile?.plansVisible ?? false) loadPastPlans(),
    ]);
  }

  Future<void> _loadFriendship(PublicProfile profile) async {
    final friends = friendshipRepository;
    final account = currentUserId;
    if (isUserBlocked) {
      _friendship = FriendshipAction.unavailable;
      _incoming = null;
      return;
    }
    final confirmed = account == null
        ? null
        : friends?.confirmedFriendship(account, userId);
    if (profile.isFriend == true ||
        (profile.isFriend == null && confirmed == true)) {
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

  Future<bool> removeFriend() async {
    if (!canRemoveFriend) return false;
    final revision = _revision;
    _removingFriend = true;
    _friendRequestError = null;
    notifyListeners();
    try {
      await friendshipRepository!.removeFriend(
        userId: currentUserId!,
        friendId: _profile?.profile.userId ?? userId,
      );
      return !_isDisposed;
    } catch (_) {
      if (!_isDisposed && revision == _revision) {
        _friendRequestError = currentL10n.friendRemoveError;
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _removingFriend = false;
        notifyListeners();
        _flushRefresh();
      }
    }
  }

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
        _blockBusy ||
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
    if (_isDisposed ||
        _blockBusy ||
        isUserBlocked ||
        _friendship != FriendshipAction.add) {
      return;
    }
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
    final revision = _revision;
    state
      ..isLoading = true
      ..error = null;
    notifyListeners();
    try {
      final items = await fetch();
      if (_isDisposed || revision != _revision) return;
      if (identical(state, _plans) && !(_profile?.plansVisible ?? false)) {
        return;
      }
      state.items = items;
    } catch (_) {
      if (_isDisposed || revision != _revision) return;
      state.error = errorText();
    } finally {
      if (!_isDisposed) {
        state.isLoading = false;
        notifyListeners();
        _flushRefresh();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_friendChanges?.cancel());
    unawaited(_friendRemovals?.cancel());
    unawaited(_blockChanges?.cancel());
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
