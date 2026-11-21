import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/push_message.dart';
import '../repositories/push_repository.dart';

/// Firebase Cloud Messaging on Android (#265). While the app is closed or in
/// the background, the system shows the push by itself.
// TODO(DP-072): iOS and the web are not configured for push.
class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  String get platform => 'android';

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// The Firebase Installation ID; the backend accepts it as a target, like
  /// the old registration tokens.
  @override
  Future<void> register() => _messaging.register();

  @override
  Stream<String> get onRegistered => _messaging.onRegistered;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_toMessage);

  @override
  Stream<PushMessage> get onMessageOpened =>
      FirebaseMessaging.onMessageOpenedApp.map(_toMessage);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _toMessage(message);
  }

  static PushMessage _toMessage(RemoteMessage message) => PushMessage.fromData(
    message.data,
    title: message.notification?.title,
    body: message.notification?.body,
  );
}
