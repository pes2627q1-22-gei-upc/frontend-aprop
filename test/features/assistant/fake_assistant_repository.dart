import 'package:aprop/features/assistant/models/assistant_message.dart';
import 'package:aprop/features/assistant/repositories/assistant_repository.dart';

class FakeAssistantRepository implements AssistantRepository {
  final List<String> receivedQueries = [];
  Future<AssistantMessage> Function(String query)? onSendMessage;

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
