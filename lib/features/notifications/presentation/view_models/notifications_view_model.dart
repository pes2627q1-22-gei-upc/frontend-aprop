import 'package:flutter/foundation.dart';

import '../../models/app_notification.dart';
import '../../repositories/notification_repository.dart';
import '../../../../core/l10n/locale_controller.dart';

/// Inbox state for a single signed-in account. Contains no navigation/widgets.
class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({
    required this.userId,
    required this._repository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final String userId;
  final NotificationRepository _repository;
  final DateTime Function() _now;
  List<AppNotification> _notifications = const [];
  NotificationCategory? _filter;
  final Set<String> _reading = {};
  final Set<String> _responding = {};
  final Map<String, String> _errors = {};
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isDisposed = false;
  String? _errorMessage;

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get visibleNotifications => List.unmodifiable(
    _notifications.where((n) => _filter == null || n.category == _filter),
  );
  NotificationCategory? get filter => _filter;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  DateTime get today {
    final now = _now().toLocal();
    return DateTime(now.year, now.month, now.day);
  }

  bool isReading(String id) => _reading.contains(id);
  bool isResponding(String requestId) => _responding.contains(requestId);
  String? errorFor(String id) => _errors[id];

  void selectFilter(NotificationCategory? category) {
    if (_isDisposed || category == _filter) return;
    _filter = category;
    notifyListeners();
  }

  Future<void> load() async {
    // A refresh cannot overwrite a concurrent read/response confirmation.
    if (_isDisposed ||
        _isLoading ||
        _reading.isNotEmpty ||
        _responding.isNotEmpty) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getNotifications(userId);
      if (_isDisposed) return;
      final now = _now();
      final received = result.where((n) => !n.receivedAt.isAfter(now)).toList()
        ..sort((a, b) {
          final time = b.receivedAt.compareTo(a.receivedAt);
          return time == 0 ? a.id.compareTo(b.id) : time;
        });
      _notifications = List.unmodifiable(received);
      _hasLoaded = true;
      _errors.clear();
    } catch (_) {
      if (!_isDisposed) {
        _errorMessage = currentL10n.notifLoadError;
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  AppNotification? _find(String id) =>
      _notifications.where((n) => n.id == id).firstOrNull;

  Future<bool> markAsRead(String id) async {
    final notice = _find(id);
    if (_isDisposed ||
        _isLoading ||
        notice == null ||
        _reading.contains(id) ||
        _responding.contains(notice.requestId)) {
      return false;
    }
    if (notice.isRead) return true;
    _reading.add(id);
    _errors.remove(id);
    notifyListeners();
    try {
      await _repository.markAsRead(userId: userId, notificationId: id);
      if (_isDisposed) return false;
      _replaceWhere((n) => n.id == id, (n) => n.markRead());
      return true;
    } catch (_) {
      if (!_isDisposed) {
        _errors[id] = currentL10n.notifMarkReadError;
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _reading.remove(id);
        notifyListeners();
      }
    }
  }

  Future<void> respond(String id, {required bool accept}) async {
    final notice = _find(id);
    if (_isDisposed ||
        _isLoading ||
        notice == null ||
        _reading.contains(id) ||
        notice.requestStatus != FriendRequestStatus.pending ||
        _responding.contains(notice.requestId)) {
      return;
    }
    final requestId = notice.requestId!;
    _responding.add(requestId);
    _errors.remove(id);
    notifyListeners();
    try {
      final status = await _repository.respondToFriendRequest(
        userId: userId,
        requestId: requestId,
        accept: accept,
      );
      if (_isDisposed) return;
      if (status == FriendRequestStatus.pending) {
        throw StateError('Unconfirmed response.');
      }
      _replaceWhere(
        (n) => n.requestId == requestId,
        (n) => n.resolveRequest(status),
      );
    } catch (_) {
      if (!_isDisposed) {
        _errors[id] = currentL10n.notifRespondError;
      }
    } finally {
      if (!_isDisposed) {
        _responding.remove(requestId);
        notifyListeners();
      }
    }
  }

  void _replaceWhere(
    bool Function(AppNotification) matches,
    AppNotification Function(AppNotification) replace,
  ) {
    _notifications = List.unmodifiable(
      _notifications.map((n) => matches(n) ? replace(n) : n),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
