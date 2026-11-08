import '../../../core/network/api_client.dart';
import '../../activities/data/activity_json_mapper.dart';
import '../../activities/models/activity.dart';
import '../models/assistant_message.dart';
import '../repositories/assistant_repository.dart';

/// Implementació d'[AssistantRepository] connectada al backend de Render
/// (`POST /assistant/messages` i `GET /assistant/conversation`).
class HttpAssistantRepository implements AssistantRepository {
  HttpAssistantRepository({required this.apiClient});

  final ApiClient apiClient;
  int _counter = 0;

  @override
  Future<AssistantMessage> sendMessage(
    String query, {
    bool isVoice = false,
  }) async {
    final decoded = await apiClient.postJson(
      'assistant/messages',
      body: <String, Object?>{'text': query, 'by-voice': isVoice},
    );

    if (decoded is! Map<String, Object?>) {
      throw ApiException('Resposta invàlida de l’assistent cultural.');
    }

    final assistantJson = switch (decoded['assistant-message']) {
      final Map<String, Object?> msg => msg,
      _ => decoded,
    };

    return _messageFromJson(
      assistantJson,
      defaultSender: AssistantMessageSender.assistant,
      conversationStartedAt: decoded['conversation-started-at'] as String?,
    );
  }

  @override
  Future<List<String>> getSuggestions(String lang) async {
    final decoded = await apiClient.getJson(
      'assistant/suggestions',
      queryParameters: {'lang': lang},
    );
    return switch (decoded) {
      {'suggestions': final List<Object?> list} => [
        for (final item in list)
          if (item is String && item.trim().isNotEmpty) item.trim(),
      ],
      _ => const <String>[],
    };
  }

  @override
  Future<void> sendFeedback({
    required String conversationStartedAt,
    required String sentAt,
    required bool helpful,
  }) async {
    await apiClient.postJson(
      'assistant/feedback',
      body: <String, Object?>{
        'conversation-started-at': conversationStartedAt,
        'sent-at': sentAt,
        'helpful': helpful,
      },
    );
  }

  /// Recupera tot l'historial de conversa de l'usuari (`GET /assistant/conversation`).
  Future<List<AssistantMessage>> getConversation() async {
    final decoded = await apiClient.getJson('assistant/conversation');
    final startedAt = decoded is Map<String, Object?>
        ? decoded['started-at'] as String?
        : null;
    final rawMessages = switch (decoded) {
      {'messages': final List<Object?> list} => list,
      final List<Object?> list => list,
      _ => const <Object?>[],
    };

    return List.unmodifiable([
      for (final item in rawMessages)
        if (item is Map<String, Object?>)
          _messageFromJson(item, conversationStartedAt: startedAt),
    ]);
  }

  AssistantMessage _messageFromJson(
    Map<String, Object?> json, {
    AssistantMessageSender defaultSender = AssistantMessageSender.assistant,
    String? conversationStartedAt,
  }) {
    _counter += 1;
    final id = json['id'] != null ? '${json['id']}' : 'assistant-msg-$_counter';
    final senderStr = (json['sender'] as String?)?.toLowerCase();
    final sender = switch (senderStr) {
      'user' => AssistantMessageSender.user,
      'assistant' || 'bot' => AssistantMessageSender.assistant,
      _ => defaultSender,
    };

    final sentAtStr = json['sent-at'] as String?;
    final sentAt = sentAtStr != null && sentAtStr.isNotEmpty
        ? DateTime.parse(sentAtStr)
        : DateTime.now();

    final text = json['text'] as String? ?? '';
    final byVoice = json['by-voice'] as bool? ?? false;

    if (sender == AssistantMessageSender.user) {
      return AssistantMessage.user(
        id: id,
        text: text,
        sentAt: sentAt,
        isVoice: byVoice,
      );
    }

    AssistantInterpretation? interpretation;
    if (json['interpretation'] case final Map<String, Object?> interpJson) {
      final interp = AssistantInterpretation(
        category: _nonEmpty(interpJson['category']),
        municipality: _nonEmpty(interpJson['municipality']),
        dateRange:
            _nonEmpty(interpJson['date-range']) ??
            _nonEmpty(interpJson['date-from']),
      );
      if (interp.hasAny) {
        interpretation = interp;
      }
    }

    final rawRecommended = json['recommended-events'];
    final recommended = <Activity>[
      if (rawRecommended is List<Object?>)
        for (final item in rawRecommended)
          if (item is Map<String, Object?>) activityFromJson(item),
    ];

    return AssistantMessage.assistant(
      id: id,
      text: text,
      sentAt: sentAt,
      interpretation: interpretation,
      recommendedActivities: recommended,
      action: switch (json['action']) {
        {'screen': final Object? screen} => AssistantScreenTarget.fromApi(
          screen,
        ),
        _ => null,
      },
      rawSentAt: sentAtStr,
      conversationStartedAt: conversationStartedAt,
    );
  }

  String? _nonEmpty(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
