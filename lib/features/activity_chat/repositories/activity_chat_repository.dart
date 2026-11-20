import '../models/activity_message.dart';

/// Text més llarg que accepta el xat. Es compta en punts de codi (runes),
/// com el backend: un emoji compost en pot ocupar més d'un.
const maxActivityMessageLength = 1000;

/// Llargada d'un missatge tal com la compta el backend.
int activityMessageLength(String text) => text.runes.length;

/// Missatges per pàgina.
const activityMessagePageSize = 50;

/// Només qui s'hi ha apuntat pot fer servir el xat d'una activitat (R11).
class NotEnrolledInChatException implements Exception {
  const NotEnrolledInChatException();
}

/// El backend ha rebutjat el text (massa llarg o buit): tornar-ho a provar
/// no serveix de res.
class MessageRejectedException implements Exception {
  const MessageRejectedException();
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
  /// [maxActivityMessageLength] runes) i retorna el missatge desat. Llança
  /// [MessageRejectedException] si el backend el rebutja.
  Future<ActivityMessage> sendMessage(String activityId, String text);
}
