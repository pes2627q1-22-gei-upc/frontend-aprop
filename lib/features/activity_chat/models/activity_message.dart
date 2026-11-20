/// Missatge del xat d'una activitat (`Missatge`), amb el seu autor.
class ActivityMessage {
  const ActivityMessage({
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.sentAt,
  });

  final String authorId;

  /// Nom per mostrar: el nom de la persona o, si no en té, el nom d'usuari.
  final String authorName;
  final String text;

  /// `dataEnviament`.
  final DateTime sentAt;

  /// Els missatges no tenen identificador: el backend no deixa que un autor
  /// n'enviï dos al mateix instant, així que autor i data n'identifiquen un.
  String get key => '$authorId@${sentAt.toUtc().microsecondsSinceEpoch}';
}

/// Una pàgina del xat, del missatge més nou al més antic.
class ActivityMessagePage {
  const ActivityMessagePage({required this.messages, required this.total});

  final List<ActivityMessage> messages;

  /// Tots els missatges de l'activitat, no només els d'aquesta pàgina.
  final int total;
}
