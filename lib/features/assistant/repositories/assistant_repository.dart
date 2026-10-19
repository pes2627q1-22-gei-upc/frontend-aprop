import '../models/assistant_message.dart';

/// Contract for asking the cultural assistant for activity recommendations.
///
/// Implementations return an [AssistantMessage] authored by
/// [AssistantMessageSender.assistant] with the reply text, any interpreted
/// criteria (category, municipality, date range) and matching activities.
/// Throws when the assistant service or catalogue cannot be reached.
abstract interface class AssistantRepository {
  Future<AssistantMessage> sendMessage(String query);
}
