import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity_message.dart';
import '../../repositories/activity_chat_repository.dart';

/// Xat d'una activitat: l'historial, els missatges nous i l'enviament.
///
/// El backend no avisa dels missatges nous, així que mentre el xat és obert
/// (i l'app és en primer pla) es tornen a demanar cada [pollInterval].
// TODO(DP-062): sense temps real al backend.
class ActivityChatViewModel extends ChangeNotifier {
  ActivityChatViewModel({
    required this.activityId,
    required this.userId,
    required this._repository,
    this.pollInterval = const Duration(seconds: 5),
  });

  final String activityId;

  /// Qui fa servir l'app, per saber quins missatges són seus.
  final String userId;
  final ActivityChatRepository _repository;
  final Duration pollInterval;

  /// Del més antic al més nou, com es llegeixen.
  List<ActivityMessage> _messages = const [];
  int _total = 0;
  bool _hasLoaded = false;
  bool _isRefreshing = false;
  bool _isPaused = false;
  bool _notEnrolled = false;
  bool _isLoading = false;
  bool _isLoadingOlder = false;
  bool _isSending = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _olderError;
  String? _sendError;
  Timer? _poll;

  List<ActivityMessage> get messages => _messages;
  bool get hasLoaded => _hasLoaded;
  bool get isLoading => _isLoading;
  bool get isLoadingOlder => _isLoadingOlder;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  String? get olderError => _olderError;
  String? get sendError => _sendError;

  /// La persona no hi està apuntada (R11): tornar-ho a provar no serveix.
  bool get isNotEnrolled => _notEnrolled;

  /// Hi ha missatges més antics que encara no s'han carregat.
  bool get hasOlder => _hasLoaded && _messages.length < _total;

  bool isMine(ActivityMessage message) => message.authorId == userId;

  /// Carrega els missatges més recents i comença a demanar-ne de nous.
  Future<void> load() async {
    if (_isLoading || _isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    _notEnrolled = false;
    notifyListeners();

    try {
      final page = await _repository.getMessages(activityId);
      if (_isDisposed) return;
      _messages = _merge(const [], page.messages);
      _total = page.total;
      _hasLoaded = true;
      _startPolling();
    } on NotEnrolledInChatException {
      if (_isDisposed) return;
      _notEnrolled = true;
      _errorMessage = currentL10n.chatNotEnrolled;
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = currentL10n.chatLoadError;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Afegeix els missatges nous. Si falla, es torna a provar la propera
  /// vegada sense molestar la persona.
  Future<void> refresh() async {
    // Amb una xarxa lenta, una petició no se'n troba una altra pel camí.
    if (_isDisposed || _isLoading || _isRefreshing || !_hasLoaded) return;
    _isRefreshing = true;
    try {
      final page = await _repository.getMessages(activityId);
      if (_isDisposed) return;
      final merged = _merge(_messages, page.messages);
      _total = page.total;
      if (merged.length != _messages.length) {
        _messages = merged;
        notifyListeners();
      }
    } catch (_) {
      // Sense connexió: els missatges ja carregats continuen a la pantalla.
    } finally {
      _isRefreshing = false;
    }
  }

  /// L'app passa a segon pla: deixa de demanar missatges (bateria i dades).
  void pause() {
    _isPaused = true;
    _poll?.cancel();
    _poll = null;
  }

  /// L'app torna: demana els missatges nous de seguida i continua.
  void resume() {
    if (!_isPaused || _isDisposed) return;
    _isPaused = false;
    if (!_hasLoaded) return;
    _startPolling();
    refresh();
  }

  void _startPolling() {
    if (_isPaused || _isDisposed) return;
    _poll ??= Timer.periodic(pollInterval, (_) => refresh());
  }

  Future<void> loadOlder() async {
    if (_isLoadingOlder || !hasOlder || _isDisposed) return;
    _isLoadingOlder = true;
    _olderError = null;
    notifyListeners();

    try {
      // Les pàgines van per posició des del més nou. Amb els refrescos, els
      // ja carregats són els més recents, així que la pàgina on acaben és la
      // que té els anteriors (si n'han arribat de nous, en repeteix alguns,
      // que es descarten en ajuntar-los).
      // TODO(DP-062): si n'arriben més d'una pàgina entre dos refrescos, pot
      // quedar un forat a l'historial.
      final first = _messages.firstOrNull;
      var pageIndex = _messages.length ~/ activityMessagePageSize;
      var added = false;
      while (!added) {
        final page = await _repository.getMessages(activityId, page: pageIndex);
        if (_isDisposed) return;
        final merged = _merge(_messages, page.messages);
        _total = page.total;
        added = first == null
            ? merged.isNotEmpty
            : merged.first.sentAt.isBefore(first.sentAt);
        _messages = merged;
        // Una pàgina sense res d'anterior: la següent segur que en té.
        if (added || page.messages.isEmpty || !hasOlder) break;
        pageIndex++;
      }
    } catch (_) {
      if (_isDisposed) return;
      _olderError = currentL10n.chatLoadError;
    } finally {
      if (!_isDisposed) {
        _isLoadingOlder = false;
        notifyListeners();
      }
    }
  }

  /// Envia [text]. Retorna cert si s'ha enviat, per buidar el camp de text;
  /// si no, el text es conserva per tornar-ho a provar.
  Future<bool> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending || _isDisposed) return false;
    if (activityMessageLength(trimmed) > maxActivityMessageLength) {
      _sendError = currentL10n.chatMessageTooLong;
      notifyListeners();
      return false;
    }
    _isSending = true;
    _sendError = null;
    notifyListeners();

    try {
      final message = await _repository.sendMessage(activityId, trimmed);
      if (_isDisposed) return true;
      final merged = _merge(_messages, [message]);
      if (merged.length != _messages.length) _total++;
      _messages = merged;
      return true;
    } on NotEnrolledInChatException {
      if (!_isDisposed) _sendError = currentL10n.chatNotEnrolled;
      return false;
    } on MessageRejectedException {
      if (!_isDisposed) _sendError = currentL10n.chatMessageTooLong;
      return false;
    } catch (_) {
      if (!_isDisposed) _sendError = currentL10n.chatSendError;
      return false;
    } finally {
      if (!_isDisposed) {
        _isSending = false;
        notifyListeners();
      }
    }
  }

  /// Ajunta els missatges sense repetir-ne cap i en ordre cronològic.
  static List<ActivityMessage> _merge(
    List<ActivityMessage> current,
    List<ActivityMessage> incoming,
  ) {
    final byKey = {
      for (final message in current) message.key: message,
      for (final message in incoming) message.key: message,
    };
    final merged = byKey.values.toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return List.unmodifiable(merged);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _poll?.cancel();
    super.dispose();
  }
}
