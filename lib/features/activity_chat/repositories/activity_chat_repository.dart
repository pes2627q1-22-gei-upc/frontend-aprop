import '../models/activity_message.dart';

/// Text més llarg que accepta el xat, en caràcters.
const maxActivityMessageLength = 1000;

/// Missatges per pàgina.
const activityMessagePageSize = 50;

/// Només qui s'hi ha apuntat pot fer servir el xat d'una activitat (R11).
class NotEnrolledInChatException implements Exception {
  const NotEnrolledInChatException();
}

/// Xat d'una activitat entre les persones que s'hi han apuntat.
abstract interface class ActivityChatRepository {
  /// Pàgina [page] (0 és la més recent) dels missatges de [activityId], del
  /// més nou al més antic. Llança [NotEnrolledInChatException] si la persona
  /// no hi està apuntada.
  Future<ActivityMessagePage> getMessages(
    String activityId, {
    int page = 0,
    int pageSize = activityMessagePageSize,
  });

  /// Envia [text] (sense espais als extrems, d'1 a
  /// [maxActivityMessageLength] caràcters) i retorna el missatge desat.
  Future<ActivityMessage> sendMessage(String activityId, String text);
}
