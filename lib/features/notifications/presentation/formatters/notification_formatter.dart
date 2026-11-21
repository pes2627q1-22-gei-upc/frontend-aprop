import '../../../../core/l10n/date_labels.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../../activities/models/activity.dart';
import '../../../activities/presentation/formatters/activity_date_formatter.dart';
import '../../models/app_notification.dart';

String notificationCategoryLabel(NotificationCategory? category) =>
    switch (category) {
      NotificationCategory.social => currentL10n.notifCategorySocial,
      NotificationCategory.reminders => currentL10n.notifCategoryReminder,
      NotificationCategory.recommendations =>
        currentL10n.notifCategoryRecommendation,
      null => currentL10n.notifCategoryNotice,
    };

String notificationFilterLabel(NotificationCategory? category) =>
    switch (category) {
      null => currentL10n.notifFilterAll,
      NotificationCategory.social => currentL10n.notifCategorySocial,
      NotificationCategory.reminders => currentL10n.notifFilterReminders,
      NotificationCategory.recommendations =>
        currentL10n.notifFilterRecommendations,
    };

String notificationMessage(AppNotification notice) {
  final l10n = currentL10n;
  return switch (notice.type) {
    NotificationType.reminder =>
      notice.activity?.title ?? l10n.notifMessageReminder,
    NotificationType.recommendation =>
      notice.activity == null
          ? l10n.notifMessageRecommendation
          : l10n.notifMessageRecommendationFor(notice.activity!.title),
    NotificationType.socialUpdate =>
      notice.activity != null
          ? l10n.notifMessageSocialAbout(notice.activity!.title)
          : notice.person != null
          ? l10n.notifMessageSocialPerson(notice.person!.name)
          : l10n.notifMessageSocial,
    NotificationType.activityCancelled =>
      notice.activity == null
          ? l10n.notifMessageCancelled
          : l10n.notifMessageCancelledFor(notice.activity!.title),
    NotificationType.other => l10n.notifMessageOther,
    NotificationType.activityPublished => l10n.notifMessagePublished(
      notice.person!.name,
      notice.activity!.title,
    ),
    NotificationType.friendEnrolled => l10n.notifMessageEnrolled(
      notice.person!.name,
      notice.activity!.title,
    ),
    NotificationType.friendRequest => l10n.notifMessageFriendRequest(
      notice.person!.name,
    ),
    NotificationType.friendRequestAccepted => l10n.notifMessageFriendAccepted(
      notice.person!.name,
    ),
  };
}

String notificationTime(DateTime date) => timeOfDay(date.toLocal());

String notificationDayLabel(DateTime date, DateTime today) {
  final local = date.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final current = DateTime(today.year, today.month, today.day);
  if (day == current) return currentL10n.today;
  if (day == DateTime(current.year, current.month, current.day - 1)) {
    return currentL10n.yesterday;
  }
  return notificationDate(day);
}

String notificationDate(DateTime date) => dateWithYear(date.toLocal());

/// «26 de setembre de 2026 · 19.00 h». The hour follows the activity's
/// schedule, as in its card and detail; never «00.00 h» when it is unknown.
String notificationActivitySchedule(Activity activity) {
  final date = activity.startsAt;
  if (date.year == 1 && date.month == 1 && date.day == 1) {
    return currentL10n.dateUnknown;
  }
  final day = notificationDate(date);
  final time = activityTimeLabel(activity, short: true);
  return time == null ? day : currentL10n.scheduleJoin(day, time);
}
