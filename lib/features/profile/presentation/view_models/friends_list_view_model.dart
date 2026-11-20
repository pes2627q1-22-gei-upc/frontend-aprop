import 'package:flutter/foundation.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/user_summary.dart';
import '../../repositories/friends_repository.dart';

/// A person's friends (#54), with loading, empty and error states.
class FriendsListViewModel extends ChangeNotifier {
  FriendsListViewModel({
    required this.repository,
    this.userId,
    this.hiddenIds = const {},
  });

  final FriendsRepository repository;

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

  Future<void> load() async {
    if (_isDisposed || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getFriends(userId: userId);
      if (_isDisposed) return;
      _friends = List.unmodifiable(
        result.where((friend) => !hiddenIds.contains(friend.id)),
      );
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = currentL10n.friendsLoadError;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
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
