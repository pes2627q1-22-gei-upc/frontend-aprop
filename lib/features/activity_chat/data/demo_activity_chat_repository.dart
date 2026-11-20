import '../models/activity_message.dart';
import '../repositories/activity_chat_repository.dart';

/// Xat de demostració en memòria, per quan l'app no té backend. Cada
/// activitat comença amb una salutació d'una altra persona.
class DemoActivityChatRepository implements ActivityChatRepository {
  DemoActivityChatRepository({
    required this.authorId,
    required this.authorName,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Qui envia els missatges des d'aquesta app.
  final String authorId;
  final String authorName;
  final DateTime Function() _now;

  /// Del més antic al més nou.
  final Map<String, List<ActivityMessage>> _messages = {};

  List<ActivityMessage> _chat(String activityId) =>
      _messages.putIfAbsent(activityId, () {
        return [
          ActivityMessage(
            authorId: 'demo-laiasoler',
            authorName: 'Laia Soler',
            text: 'Hola! Hi anirà algú més? Podríem quedar una mica abans.',
            sentAt: _now().subtract(const Duration(hours: 2)),
          ),
        ];
      });

  @override
  Future<ActivityMessagePage> getMessages(
    String activityId, {
    int page = 0,
    int pageSize = activityMessagePageSize,
  }) async {
    final newestFirst = _chat(activityId).reversed.toList();
    return ActivityMessagePage(
      messages: newestFirst.skip(page * pageSize).take(pageSize).toList(),
      total: newestFirst.length,
    );
  }

  @override
  Future<ActivityMessage> sendMessage(String activityId, String text) async {
    final message = ActivityMessage(
      authorId: authorId,
      authorName: authorName,
      text: text,
      sentAt: _now(),
    );
    _chat(activityId).add(message);
    return message;
  }
}
