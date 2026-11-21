import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/blocked_user.dart';
import '../../repositories/user_blocking_repository.dart';

class BlockedUsersViewModel extends ChangeNotifier {
  BlockedUsersViewModel({required this.userId, required this.repository}) {
    _users = repository.cachedBlockedUsers(userId);
    _changes = repository.watchBlocks(userId).listen((_) {
      if (_disposed) return;
      _users = repository.cachedBlockedUsers(userId);
      notifyListeners();
    });
  }
  final String userId;
  final UserBlockingRepository repository;
  StreamSubscription<void>? _changes;
  List<BlockedUser>? _users;
  final _unblocking = <String>{};
  final _errors = <String, String>{};
  bool _loading = false;
  bool _disposed = false;
  String? _error;

  List<BlockedUser>? get users => _users;
  bool get isLoading => _loading;
  String? get errorMessage => _error;
  bool isUnblocking(String id) => _unblocking.contains(id);
  String? actionError(String id) => _errors[id];

  Future<void> load() async {
    if (_disposed || _loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await repository.getBlockedUsers(userId);
      if (!_disposed) _users = repository.cachedBlockedUsers(userId);
    } catch (_) {
      if (!_disposed) _error = currentL10n.blockedLoadError;
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> unblock(String id) async {
    if (_disposed ||
        _loading ||
        isUnblocking(id) ||
        !(_users?.any((row) => row.user.id == id) ?? false)) {
      return false;
    }
    _unblocking.add(id);
    _errors.remove(id);
    notifyListeners();
    try {
      await repository.unblockUser(userId: userId, targetId: id);
      return !_disposed;
    } catch (_) {
      if (!_disposed) _errors[id] = currentL10n.userUnblockError;
      return false;
    } finally {
      if (!_disposed) {
        _unblocking.remove(id);
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_changes?.cancel());
    super.dispose();
  }
}
