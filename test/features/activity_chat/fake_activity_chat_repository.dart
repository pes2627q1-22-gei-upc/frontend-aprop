import 'dart:async';

import 'package:aprop/features/activity_chat/models/activity_message.dart';
import 'package:aprop/features/activity_chat/repositories/activity_chat_repository.dart';

ActivityMessage chatMessage(
  String text, {
  String authorId = 'laia',
  String authorName = 'Laia Soler',
  required DateTime sentAt,
}) => ActivityMessage(
  authorId: authorId,
  authorName: authorName,
  text: text,
  sentAt: sentAt,
);

class FakeActivityChatRepository implements ActivityChatRepository {
  /// Missatges del xat, del més antic al més nou.
  List<ActivityMessage> messages = [];

  /// Si no és nul, [getMessages] el llança.
  Object? loadError;

  /// Si no és nul, [sendMessage] el llança.
  Object? sendError;

  /// Si no és nul, [sendMessage] espera que es completi.
  Completer<void>? pendingSend;

  final requestedPages = <int>[];
  final sent = <String>[];

  /// Hora que tindrà el missatge enviat.
  DateTime Function() now = () => DateTime(2026, 11, 20, 18, 30);

  @override
  Future<ActivityMessagePage> getMessages(
    String activityId, {
    int page = 0,
    int pageSize = activityMessagePageSize,
  }) async {
    requestedPages.add(page);
    if (loadError case final error?) throw error;
    final newestFirst = messages.reversed.toList();
    return ActivityMessagePage(
      messages: newestFirst.skip(page * pageSize).take(pageSize).toList(),
      total: newestFirst.length,
    );
  }

  @override
  Future<ActivityMessage> sendMessage(String activityId, String text) async {
    sent.add(text);
    await pendingSend?.future;
    if (sendError case final error?) throw error;
    final message = chatMessage(
      text,
      authorId: 'me',
      authorName: 'Sukh',
      sentAt: now(),
    );
    messages.add(message);
    return message;
  }
}
