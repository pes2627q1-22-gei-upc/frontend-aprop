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
      messages: [
        for (final message in decoded['messages'] as List)
          _messageFrom(message),
      ],
      total: (decoded['total'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<ActivityMessage> sendMessage(String activityId, String text) async {
    final decoded = await _call(
      () => apiClient.postJson(
        'events/$activityId/messages',
        body: {'text': text},
      ),
    );
    return _messageFrom(decoded);
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

  static ActivityMessage _messageFrom(Object? json) {
    if (json is! Map<String, Object?>) {
      throw ApiException('Missatge del xat invàlid.');
    }
    final name = (json['name'] as String?)?.trim() ?? '';
    return ActivityMessage(
      authorId: json['user-id'] as String? ?? '',
      authorName: name.isNotEmpty ? name : json['username'] as String? ?? '',
      text: json['text'] as String? ?? '',
      sentAt: DateTime.parse(json['date-sent'] as String).toLocal(),
    );
  }
}
