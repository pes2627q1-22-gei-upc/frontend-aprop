import '../../models/app_notification.dart';

String notificationCategoryLabel(NotificationCategory? category) =>
    switch (category) {
      NotificationCategory.social => 'Social',
      NotificationCategory.reminders => 'Recordatori',
      NotificationCategory.recommendations => 'Recomanació',
      null => 'Avís',
    };

String notificationFilterLabel(NotificationCategory? category) =>
    switch (category) {
      null => 'Tots',
      NotificationCategory.social => 'Social',
      NotificationCategory.reminders => 'Recordatoris',
      NotificationCategory.recommendations => 'Recomanacions',
    };

String notificationMessage(AppNotification notice) => switch (notice.type) {
  NotificationType.reminder =>
    notice.activity?.title ?? 'Tens un recordatori cultural.',
  NotificationType.recommendation =>
    notice.activity == null
        ? 'Tens una recomanació cultural.'
        : '“${notice.activity!.title}” et pot interessar.',
  NotificationType.socialUpdate =>
    notice.activity != null
        ? 'Avís social sobre “${notice.activity!.title}”.'
        : notice.person != null
        ? 'Tens un avís social relacionat amb ${notice.person!.name}.'
        : 'Tens un nou avís social.',
  NotificationType.other => 'Tens un nou avís.',
  NotificationType.activityPublished =>
    '${notice.person!.name} ha publicat “${notice.activity!.title}”.',
  NotificationType.friendEnrolled =>
    '${notice.person!.name} s’ha apuntat a “${notice.activity!.title}”.',
  NotificationType.friendRequest =>
    '${notice.person!.name} t’ha enviat una sol·licitud d’amistat.',
  NotificationType.friendRequestAccepted =>
    '${notice.person!.name} ha acceptat la teva sol·licitud d’amistat.',
};

String notificationTime(DateTime date) {
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')} h';
}

String notificationDayLabel(DateTime date, DateTime today) {
  final local = date.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final current = DateTime(today.year, today.month, today.day);
  if (day == current) return 'Avui';
  if (day == DateTime(current.year, current.month, current.day - 1)) {
    return 'Ahir';
  }
  return notificationDate(day);
}

String notificationDate(DateTime date) {
  final day = date.toLocal();
  const months = [
    'gener',
    'febrer',
    'març',
    'abril',
    'maig',
    'juny',
    'juliol',
    'agost',
    'setembre',
    'octubre',
    'novembre',
    'desembre',
  ];
  final month = months[day.month - 1];
  final preposition = day.month == 4 || day.month == 8 || day.month == 10
      ? 'd’'
      : 'de ';
  return '${day.day} $preposition$month de ${day.year}';
}

String notificationActivitySchedule(DateTime date) =>
    date.year == 1 && date.month == 1 && date.day == 1
    ? 'Data no informada'
    : '${notificationDate(date)} · ${notificationTime(date)}';
