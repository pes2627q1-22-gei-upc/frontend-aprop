import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity_message.dart';
import '../../repositories/activity_chat_repository.dart';

/// Xat d'una activitat: l'historial, els missatges nous i l'enviament.
///
/// El backend no avisa dels missatges nous, així que mentre el xat és obert
/// es tornen a demanar cada [pollInterval].
// TODO(DP-061): sense temps real al backend.
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
  int _nextPage = 1;
  bool _hasLoaded = false;
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

  /// Hi ha missatges més antics que encara no s'han carregat.
  bool get hasOlder => _hasLoaded && _messages.length < _total;

  bool isMine(ActivityMessage message) => message.authorId == userId;

  /// Carrega els missatges més recents i comença a demanar-ne de nous.
  Future<void> load() async {
    if (_isLoading || _isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _repository.getMessages(activityId);
      if (_isDisposed) return;
      _messages = _merge(const [], page.messages);
      _total = page.total;
      _nextPage = 1;
      _hasLoaded = true;
      _poll ??= Timer.periodic(pollInterval, (_) => refresh());
    } on NotEnrolledInChatException {
      if (_isDisposed) return;
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
    if (_isDisposed || _isLoading || !_hasLoaded) return;
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
    }
  }

  Future<void> loadOlder() async {
    if (_isLoadingOlder || !hasOlder || _isDisposed) return;
    _isLoadingOlder = true;
    _olderError = null;
    notifyListeners();

    try {
      final page = await _repository.getMessages(activityId, page: _nextPage);
      if (_isDisposed) return;
      // Si n'han arribat de nous, la pàgina es desplaça i repeteix algun
      // missatge: es descarten en ajuntar-los.
      _messages = _merge(_messages, page.messages);
      _total = page.total;
      _nextPage++;
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
