import '../../../core/network/api_client.dart';
import '../models/activity_message.dart';
import '../repositories/activity_chat_repository.dart';

/// Xat de l'activitat al backend: `GET` i `POST /events/{id}/messages`. La
/// persona s'identifica amb el token de la sessió.
class HttpActivityChatRepository implements ActivityChatRepository {
  HttpActivityChatRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<ActivityMessagePage> getMessages(
    String activityId, {
    int page = 0,
    int pageSize = activityMessagePageSize,
  }) async {
    final decoded = await _call(
      () => apiClient.getJson(
        'events/$activityId/messages',
        queryParameters: {'pageNum': '$page', 'pageSize': '$pageSize'},
      ),
    );
    if (decoded is! Map<String, Object?> || decoded['messages'] is! List) {
      throw ApiException('Resposta invàlida en carregar el xat.');
    }
    return ActivityMessagePage(
      // Un missatge mal format no amaga la resta de la pàgina.
      messages: [
        for (final message in decoded['messages'] as List)
          ?_messageFrom(message),
      ],
      total: (decoded['total'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<ActivityMessage> sendMessage(String activityId, String text) async {
    final Object? decoded;
    try {
      decoded = await _call(
        () => apiClient.postJson(
          'events/$activityId/messages',
          body: {'text': text},
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 400) throw const MessageRejectedException();
      rethrow;
    }
    return _messageFrom(decoded) ??
        (throw ApiException('Missatge del xat invàlid.'));
  }

  /// El backend respon 403 a qui no s'hi ha apuntat (R11).
  Future<Object?> _call(Future<Object?> Function() request) async {
    try {
      return await request();
    } on ApiException catch (error) {
      if (error.statusCode == 403) throw const NotEnrolledInChatException();
      rethrow;
    }
  }

  /// Nul si el missatge no és vàlid (sense data d'enviament, per exemple).
  static ActivityMessage? _messageFrom(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final sentAt = switch (json['date-sent']) {
      final String date => DateTime.tryParse(date),
      _ => null,
    };
    if (sentAt == null) return null;
    final name = switch (json['name']) {
      final String name => name.trim(),
      _ => '',
    };
    final username = switch (json['username']) {
      final String username => username,
      _ => '',
    };
    return ActivityMessage(
      authorId: switch (json['user-id']) {
        final String id => id,
        _ => '',
      },
      authorName: name.isNotEmpty ? name : username,
      text: switch (json['text']) {
        final String text => text,
        _ => '',
      },
      sentAt: sentAt.toLocal(),
    );
  }
}
