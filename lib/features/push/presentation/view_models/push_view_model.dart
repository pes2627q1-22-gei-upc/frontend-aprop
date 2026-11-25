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

  /// How long signing out may wait for the backend: it can be asleep or
  /// unreachable, and that must not keep the person signed in.
  static const signOutWait = Duration(seconds: 5);

  final _subscriptions = <StreamSubscription<Object?>>[];
  String? _deviceId;

  /// The last ID of this device, to register it again if signing out fails.
  String? _lastId;

  /// Calls to the backend, one after the other: a registration still on its
  /// way must not arrive after the sign out that cancels it.
  Future<void> _calls = Future.value();
  bool _signedOut = false;
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
      ..add(messaging.onRegistered.listen(_onRegistered))
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

  void _onRegistered(String id) {
    if (_isDisposed || id.trim().isEmpty) return;
    _lastId = id;
    if (_signedOut) return;
    _deviceId = id;
    _calls = _calls.then((_) => _registerDevice(id));
  }

  Future<void> _registerDevice(String id) async {
    if (_signedOut || _isDisposed) return;
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
    if (_signedOut) return;
    _signedOut = true;
    final id = _deviceId;
    _deviceId = null;
    if (id == null) return;
    _calls = _calls.then((_) => _unregisterDevice(id));
    try {
      await _calls.timeout(signOutWait);
    } on TimeoutException {
      // The request goes on by itself; if it never arrives, the device moves
      // to the next account that signs in on it.
      debugPrint('Signing out without waiting for the push backend.');
    }
  }

  Future<void> _unregisterDevice(String id) async {
    try {
      await devices.unregisterDevice(id);
    } catch (error) {
      debugPrint('Could not unregister the device: $error');
    }
  }

  /// Signing out failed: the person is still here and wants the pushes.
  void resume() {
    if (!_signedOut || _isDisposed) return;
    _signedOut = false;
    if (_lastId case final id?) _onRegistered(id);
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
