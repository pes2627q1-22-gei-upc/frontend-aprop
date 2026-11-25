/// A push notification as the app needs it (#265). The backend sends a title,
/// a body and, as data, the notice it comes from.
class PushMessage {
  const PushMessage({
    this.title,
    this.body,
    this.notificationId,
    this.type,
    this.activityId,
    this.friendId,
  });

  /// Reads the data the backend adds to every push (`notification-id`,
  /// `type`, and `event-id` or `friend-id` when the notice has them).
  factory PushMessage.fromData(
    Map<String, Object?> data, {
    String? title,
    String? body,
  }) {
    String? text(String key) => switch (data[key]) {
      final String value when value.trim().isNotEmpty => value.trim(),
      _ => null,
    };
    return PushMessage(
      title: title,
      body: body,
      notificationId: text('notification-id'),
      type: text('type'),
      activityId: text('event-id'),
      friendId: text('friend-id'),
    );
  }

  final String? title;
  final String? body;
  final String? notificationId;

  /// The backend's notice type («Social», «Recordatori», «Cancelacio»…).
  final String? type;

  /// The activity the notice is about, if any.
  final String? activityId;
  final String? friendId;
}
