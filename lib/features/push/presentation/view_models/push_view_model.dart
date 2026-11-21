import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/push_message.dart';
import '../../repositories/push_repository.dart';

/// Push notifications of the signed-in person (#265). Registers the device
/// with the backend, reports pushes to the app and unregisters on sign out.
/// Nothing here may stop the app from working: a refused permission or a
/// failed registration only means no pushes (the notices stay in Avisos).
class PushViewModel extends ChangeNotifier {
  PushViewModel({
    required this.messaging,
    required this.devices,
    required this.onOpened,
    required this.onForeground,
  });

  final PushMessaging messaging;
  final PushDeviceRepository devices;

  /// The person tapped a push: show what it is about.
  final ValueChanged<PushMessage> onOpened;

  /// A push arrived with the app open: the system does not show it.
  final ValueChanged<PushMessage> onForeground;

  final _subscriptions = <StreamSubscription<Object?>>[];
  String? _deviceId;
  bool _started = false;
  bool _permissionDenied = false;
  bool _isDisposed = false;

  /// The person refused notifications on this device.
  bool get permissionDenied => _permissionDenied;

  /// The ID registered with the backend, if any.
  String? get deviceId => _deviceId;

  Future<void> start() async {
    if (_started || _isDisposed) return;
    _started = true;
    _subscriptions
      ..add(messaging.onRegistered.listen(_registerDevice))
      ..add(messaging.onForegroundMessage.listen(_whenOpen(onForeground)))
      ..add(messaging.onMessageOpened.listen(_whenOpen(onOpened)));
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null && !_isDisposed) onOpened(initial);
      final granted = await messaging.requestPermission();
      if (_isDisposed) return;
      if (!granted) {
        _permissionDenied = true;
        notifyListeners();
        return;
      }
      await messaging.register();
    } catch (error) {
      // Without push the app works the same; the notices stay in Avisos.
      debugPrint('Push not available: $error');
    }
  }

  ValueChanged<PushMessage> _whenOpen(ValueChanged<PushMessage> callback) =>
      (message) {
        if (!_isDisposed) callback(message);
      };

  Future<void> _registerDevice(String id) async {
    if (_isDisposed || id.trim().isEmpty) return;
    _deviceId = id;
    try {
      await devices.registerDevice(token: id, platform: messaging.platform);
    } catch (error) {
      // Tried again the next time the app starts or the ID changes.
      debugPrint('Could not register the device for push: $error');
    }
  }

  /// Before signing out, while the session can still call the backend, so
  /// the next person to use this phone does not get these pushes.
  Future<void> unregister() async {
    final id = _deviceId;
    _deviceId = null;
    if (id == null) return;
    try {
      await devices.unregisterDevice(id);
    } catch (error) {
      // The backend drops the device when FCM rejects it later.
      debugPrint('Could not unregister the device: $error');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
