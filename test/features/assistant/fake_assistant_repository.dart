import 'package:aprop/features/assistant/models/assistant_message.dart';
import 'package:aprop/features/assistant/repositories/assistant_repository.dart';

class FakeAssistantRepository implements AssistantRepository {
  final List<String> receivedQueries = [];
  Future<AssistantMessage> Function(String query)? onSendMessage;

  List<String> suggestions = const [];
  Object? suggestionsError;
  final List<({String startedAt, String sentAt, bool helpful})> feedbacks = [];
  Object? feedbackError;

  @override
  Future<List<String>> getSuggestions(String lang) async {
    if (suggestionsError case final error?) throw error;
    return suggestions;
  }

  @override
  Future<void> sendFeedback({
    required String conversationStartedAt,
    required String sentAt,
    required bool helpful,
  }) async {
    if (feedbackError case final error?) throw error;
    feedbacks.add((
      startedAt: conversationStartedAt,
      sentAt: sentAt,
      helpful: helpful,
    ));
  }

  @override
  Future<AssistantMessage> sendMessage(String query) async {
    receivedQueries.add(query);
    if (onSendMessage != null) {
      return onSendMessage!(query);
    }
    return AssistantMessage.assistant(
      id: 'fake-reply-${receivedQueries.length}',
      text: 'Resposta per a: $query',
      sentAt: DateTime(2026, 9, 26, 12),
    );
  }
}
