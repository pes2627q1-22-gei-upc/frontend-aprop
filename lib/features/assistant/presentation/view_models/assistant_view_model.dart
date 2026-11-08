import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
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
  List<String> _suggestions = const [];
  bool _suggestionsRequested = false;
  final Map<String, bool> _ratings = {};
  final Set<String> _unratable = {};
  final Set<String> _rating = {};
  String? _feedbackError;

  List<AssistantMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Quick replies, available during the whole conversation.
  List<String> get suggestions => _suggestions;
  String? get feedbackError => _feedbackError;

  /// Selected rating of [message]: true = useful, false = not useful.
  bool? ratingOf(AssistantMessage message) => _ratings[message.id];

  /// False when the message cannot be rated (local text or backend said 404).
  bool canRate(AssistantMessage message) =>
      message.canRate && !_unratable.contains(message.id);

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

  /// Loads the quick replies once; failure just means no chips.
  Future<void> loadSuggestions({String lang = 'ca'}) async {
    if (_suggestionsRequested || _isDisposed) return;
    _suggestionsRequested = true;
    try {
      final loaded = await _repository.getSuggestions(lang);
      if (_isDisposed) return;
      _suggestions = List.unmodifiable(loaded);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> rate(AssistantMessage message, {required bool helpful}) async {
    if (!canRate(message) ||
        _rating.contains(message.id) ||
        _ratings[message.id] == helpful ||
        _isDisposed) {
      return;
    }
    _rating.add(message.id);
    _feedbackError = null;
    try {
      await _repository.sendFeedback(
        conversationStartedAt: message.conversationStartedAt!,
        sentAt: message.rawSentAt!,
        helpful: helpful,
      );
      _ratings[message.id] = helpful;
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        _unratable.add(message.id);
      } else {
        _feedbackError = 'No hem pogut desar la valoració. Torna-ho a provar.';
      }
    } catch (_) {
      _feedbackError = 'No hem pogut desar la valoració. Torna-ho a provar.';
    } finally {
      _rating.remove(message.id);
      if (!_isDisposed) notifyListeners();
    }
  }

  void clearFeedbackError() => _feedbackError = null;

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
    } catch (error) {
      if (_isDisposed) return;
      _failedQuery = query;
      _errorMessage = error is ApiException && error.statusCode == 429
          ? 'Massa missatges, espera un minut'
          : 'No hem pogut obtenir les recomanacions de l’assistent. Torna-ho a provar.';
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
