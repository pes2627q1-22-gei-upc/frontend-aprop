import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/user_summary.dart';
import '../../repositories/friends_repository.dart';
import '../../repositories/friendship_repository.dart';
import '../../models/friendship_removal.dart';
import '../../models/received_friend_request.dart';

/// A person's friends (#54), with loading, empty and error states.
class FriendsListViewModel extends ChangeNotifier {
  FriendsListViewModel({
    required this.repository,
    this.userId,
    this.hiddenIds = const {},
    this.friendshipRepository,
    this.currentUserId,
  }) {
    final account = currentUserId;
    if (account == null) return;
    _removals = friendshipRepository?.watchRemovals(account).listen((_) {
      if (_isDisposed) return;
      _revision++;
      if (canRemoveFriends && _friends != null) _friends = _visible(_friends!);
      _refreshPending = true;
      notifyListeners();
      _flushRefresh();
    });
    _responses = friendshipRepository?.watchChanges(account).listen((change) {
      if (_isDisposed || change.status != FriendRequestStatus.accepted) return;
      _revision++;
      _refreshPending = true;
      _flushRefresh();
    });
  }

  final FriendsRepository repository;
  final FriendshipRepository? friendshipRepository;
  final String? currentUserId;
  StreamSubscription<FriendshipRemoval>? _removals;
  StreamSubscription<FriendRequestResolution>? _responses;
  final _removing = <String>{};
  final _removalErrors = <String, String>{};
  int _revision = 0;
  bool _refreshPending = false;

  /// Whose friends; null for the signed-in person.
  final String? userId;

  /// IDs of the signed-in person, who is never listed as a friend.
  final Set<String> hiddenIds;

  List<UserSummary>? _friends;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  /// Null until the first load succeeds.
  List<UserSummary>? get friends => _friends;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canRemoveFriends =>
      userId == null && friendshipRepository != null && currentUserId != null;
  bool isRemoving(String friendId) => _removing.contains(friendId);
  String? removalError(String friendId) => _removalErrors[friendId];

  List<UserSummary> _visible(List<UserSummary> result) => List.unmodifiable(
    result.where(
      (friend) =>
          !hiddenIds.contains(friend.id) &&
          !(canRemoveFriends &&
              friendshipRepository!.confirmedFriendship(
                    currentUserId!,
                    friend.id,
                  ) ==
                  false),
    ),
  );

  void _flushRefresh() {
    if (_isDisposed || !_refreshPending || _isLoading) return;
    _refreshPending = false;
    unawaited(load());
  }

  Future<bool> removeFriend(String friendId) async {
    if (_isDisposed ||
        !canRemoveFriends ||
        _isLoading ||
        isRemoving(friendId) ||
        !(_friends?.any((friend) => friend.id == friendId) ?? false)) {
      return false;
    }
    _removing.add(friendId);
    _removalErrors.remove(friendId);
    notifyListeners();
    try {
      await friendshipRepository!.removeFriend(
        userId: currentUserId!,
        friendId: friendId,
      );
      return !_isDisposed;
    } catch (_) {
      if (!_isDisposed) {
        _removalErrors[friendId] = currentL10n.friendRemoveError;
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _removing.remove(friendId);
        notifyListeners();
      }
    }
  }

  Future<void> load() async {
    if (_isDisposed || _isLoading) return;
    final revision = _revision;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getFriends(userId: userId);
      if (_isDisposed) return;
      if (revision != _revision) return;
      if (canRemoveFriends) {
        friendshipRepository!.reconcileFriends(
          currentUserId!,
          result.map((friend) => friend.id),
        );
      }
      _friends = _visible(result);
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = currentL10n.friendsLoadError;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
        _flushRefresh();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_removals?.cancel());
    unawaited(_responses?.cancel());
    super.dispose();
  }
}
