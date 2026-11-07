import '../models/assistant_message.dart';

/// Contract for asking the cultural assistant for activity recommendations.
///
/// Implementations return an [AssistantMessage] authored by
/// [AssistantMessageSender.assistant] with the reply text, any interpreted
/// criteria (category, municipality, date range) and matching activities.
/// Throws when the assistant service or catalogue cannot be reached.
abstract interface class AssistantRepository {
  Future<AssistantMessage> sendMessage(String query);

  /// Quick-reply questions for [lang] (`ca`, `es` or `en`).
  Future<List<String>> getSuggestions(String lang);

  /// Rates an assistant reply; rating again replaces the previous rating.
  /// Timestamps are passed exactly as received. Throws an `ApiException`
  /// with status 404 when the backend does not know the message.
  Future<void> sendFeedback({
    required String conversationStartedAt,
    required String sentAt,
    required bool helpful,
  });
}
