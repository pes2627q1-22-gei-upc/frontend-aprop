import 'package:flutter/foundation.dart';

import '../../models/assistant_message.dart';
import '../../repositories/assistant_repository.dart';

class AssistantViewModel extends ChangeNotifier {
  AssistantViewModel({required this._repository, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _messages = List.unmodifiable([
      AssistantMessage.assistant(
        id: 'assistant-welcome',
        text: welcomeText,
        sentAt: _clock(),
      ),
    ]);
  }

  static const welcomeText =
      'Hola! Sóc l’assistent d’AProp!. Digue’m quin tipus d’activitat '
      'busques, a quin municipi i per a quines dates, i et proposaré plans '
      'culturals.';

  final AssistantRepository _repository;
  final DateTime Function() _clock;

  late List<AssistantMessage> _messages;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _failedQuery;
  int _userMessageCounter = 0;

  List<AssistantMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canRetry => !_isLoading && _failedQuery != null;

  Future<void> sendMessage(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty || _isLoading || _isDisposed) return;

    _userMessageCounter += 1;
    final userMessage = AssistantMessage.user(
      id: 'user-message-$_userMessageCounter',
      text: query,
      sentAt: _clock(),
    );

    _messages = List.unmodifiable([..._messages, userMessage]);
    await _requestAssistantReply(query);
  }

  Future<void> retryLastMessage() async {
    final query = _failedQuery;
    if (query == null || _isLoading || _isDisposed) return;
    await _requestAssistantReply(query);
  }

  Future<void> _requestAssistantReply(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await _repository.sendMessage(query);
      if (_isDisposed) return;
      _failedQuery = null;
      _messages = List.unmodifiable([..._messages, reply]);
    } catch (_) {
      if (_isDisposed) return;
      _failedQuery = query;
      _errorMessage = 'No hem pogut obtenir les recomanacions de l’assistent. Torna-ho a provar.';
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
