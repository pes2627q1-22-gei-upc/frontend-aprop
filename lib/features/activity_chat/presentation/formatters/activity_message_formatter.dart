import '../../../../core/l10n/date_labels.dart';
import '../../../../core/l10n/locale_controller.dart';

/// Hora d'un missatge: només l'hora si és d'avui, «Ahir · 18.30» si és
/// d'ahir i la data si és més antic.
String formatMessageTime(DateTime sentAt, DateTime now) {
  final day = DateTime(sentAt.year, sentAt.month, sentAt.day);
  final today = DateTime(now.year, now.month, now.day);
  final time = timeOfDay(sentAt);
  if (day == today) return time;
  if (day == today.subtract(const Duration(days: 1))) {
    return '${currentL10n.yesterday} · $time';
  }
  final date = sentAt.year == now.year
      ? dateWithoutYear(sentAt)
      : dateWithYear(sentAt);
  return '$date · $time';
}
