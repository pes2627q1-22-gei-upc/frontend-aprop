import 'dart:async';

import 'package:aprop/features/push/models/push_message.dart';
import 'package:aprop/features/push/repositories/push_repository.dart';

class FakePushMessaging implements PushMessaging {
  bool grant = true;
  PushMessage? initial;
  int registerCalls = 0;

  /// The ID the push service gives this device when [register] is called.
  String? deviceId = 'device-1';

  final _registered = StreamController<String>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  void receive(PushMessage message) => _foreground.add(message);
  void open(PushMessage message) => _opened.add(message);
  void refresh(String id) => _registered.add(id);

  @override
  String get platform => 'android';

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<void> register() async {
    registerCalls++;
    if (deviceId case final id?) _registered.add(id);
  }

  @override
  Stream<String> get onRegistered => _registered.stream;

  @override
  Stream<PushMessage> get onForegroundMessage => _foreground.stream;

  @override
  Stream<PushMessage> get onMessageOpened => _opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => initial;

  Future<void> close() async {
    await _registered.close();
    await _foreground.close();
    await _opened.close();
  }
}

class FakePushDevices implements PushDeviceRepository {
  final registered = <String>[];
  final unregistered = <String>[];

  /// Every call in the order the backend finishes it.
  final log = <String>[];
  Object? registerError;

  /// If set, the backend does not answer until they complete.
  Completer<void>? registerGate;
  Completer<void>? unregisterGate;

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    if (registerError case final error?) throw error;
    await registerGate?.future;
    registered.add('$platform:$token');
    log.add('PUT $token');
  }

  @override
  Future<void> unregisterDevice(String token) async {
    unregistered.add(token);
    await unregisterGate?.future;
    log.add('DELETE $token');
  }
}
