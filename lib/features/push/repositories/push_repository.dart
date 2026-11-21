import '../models/push_message.dart';

/// The backend's list of the devices that receive the person's pushes.
abstract interface class PushDeviceRepository {
  /// Registers (or refreshes) this device's token. Throws on failure.
  Future<void> registerDevice({
    required String token,
    required String platform,
  });

  /// Stops sending pushes to [token]. Repeating it is harmless.
  Future<void> unregisterDevice(String token);
}

/// The device's push service (Firebase Cloud Messaging on Android).
abstract interface class PushMessaging {
  /// Asks the person for permission; false if they refuse.
  Future<bool> requestPermission();

  /// Asks the push service for this device's ID; it arrives through
  /// [onRegistered].
  Future<void> register();

  /// This device's ID, now and whenever it changes: it has to be sent to the
  /// backend each time.
  Stream<String> get onRegistered;

  /// A push arrived while the app was open (the system shows nothing).
  Stream<PushMessage> get onForegroundMessage;

  /// The person tapped a push while the app was in the background.
  Stream<PushMessage> get onMessageOpened;

  /// The push that opened the app from closed, if any.
  Future<PushMessage?> getInitialMessage();

  /// `android`, `ios` or `web`, as the backend expects it.
  String get platform;
}
