import 'dart:async';
import 'dart:convert';

import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/push/data/http_push_device_repository.dart';
import 'package:aprop/features/push/models/push_message.dart';
import 'package:aprop/features/push/presentation/view_models/push_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_push.dart';

void main() {
  test('Reads the data the backend adds to each push', () {
    final message = PushMessage.fromData(
      {'notification-id': '12', 'type': 'Cancelacio', 'event-id': '7'},
      title: 'Activitat cancel·lada',
      body: 'Concert s’ha cancel·lat.',
    );

    expect(message.notificationId, '12');
    expect(message.type, 'Cancelacio');
    expect(message.activityId, '7');
    expect(message.friendId, isNull);
    expect(message.body, 'Concert s’ha cancel·lat.');
  });

  group('HTTP devices (#275)', () {
    test('Registers with PUT and unregisters with DELETE', () async {
      final requests = <http.Request>[];
      final repo = HttpPushDeviceRepository(
        apiClient: ApiClient(
          idToken: () async => 'token',
          client: MockClient((request) async {
            requests.add(request);
            return http.Response('', 204);
          }),
        ),
      );

      await repo.registerDevice(token: 'fid/1', platform: 'android');
      await repo.unregisterDevice('fid/1');

      expect(requests.first.method, 'PUT');
      expect(requests.first.url.path, '/users/me/devices');
      expect(requests.first.headers['Authorization'], 'Bearer token');
      expect(jsonDecode(requests.first.body), {
        'token': 'fid/1',
        'platform': 'android',
      });
      expect(requests.last.method, 'DELETE');
      expect(requests.last.url.path, '/users/me/devices/fid%2F1');
    });

    test('An error is an error', () async {
      final repo = HttpPushDeviceRepository(
        apiClient: ApiClient(
          idToken: () async => 'token',
          client: MockClient(
            (request) async => http.Response('{"error":"bad"}', 400),
          ),
        ),
      );

      expect(
        repo.registerDevice(token: 'x', platform: 'android'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('PushViewModel', () {
    late FakePushMessaging messaging;
    late FakePushDevices devices;
    late List<PushMessage> opened;
    late List<PushMessage> received;
    late PushViewModel model;

    setUp(() {
      messaging = FakePushMessaging();
      devices = FakePushDevices();
      opened = [];
      received = [];
      model = PushViewModel(
        messaging: messaging,
        devices: devices,
        onOpened: opened.add,
        onForeground: received.add,
      );
    });
    tearDown(() async {
      model.dispose();
      await messaging.close();
    });

    test('Registers this device, and again when its ID changes', () async {
      await model.start();
      await pumpEventQueue();
      messaging.refresh('device-2');
      await pumpEventQueue();

      expect(devices.registered, ['android:device-1', 'android:device-2']);
      expect(model.deviceId, 'device-2');
    });

    test('A refused permission means no pushes, not an error', () async {
      messaging.grant = false;

      await model.start();

      expect(model.permissionDenied, isTrue);
      expect(messaging.registerCalls, 0);
      expect(devices.registered, isEmpty);
    });

    test('A failed registration does not break the app', () async {
      devices.registerError = Exception('offline');

      await model.start();
      await pumpEventQueue();

      expect(devices.registered, isEmpty);
    });

    test(
      'Reports pushes received and opened, and the one that opened the app',
      () async {
        messaging.initial = const PushMessage(activityId: '1');
        await model.start();
        messaging.receive(const PushMessage(body: 'Hola'));
        messaging.open(const PushMessage(activityId: '2'));
        await pumpEventQueue();

        expect(received.single.body, 'Hola');
        expect(opened.map((m) => m.activityId), ['1', '2']);
      },
    );

    test('Signing out stops this device from receiving pushes', () async {
      await model.start();
      await pumpEventQueue();

      await model.unregister();
      await model.unregister();

      expect(devices.unregistered, ['device-1']);
    });

    test('A registration on its way does not outlive the sign out', () async {
      devices.registerGate = Completer<void>();
      await model.start();
      await pumpEventQueue();

      final signOut = model.unregister();
      devices.registerGate!.complete();
      await signOut;

      expect(devices.log, ['PUT device-1', 'DELETE device-1']);
    });

    test('An ID that arrives after signing out is not registered', () async {
      await model.start();
      await pumpEventQueue();
      await model.unregister();

      messaging.refresh('device-2');
      await pumpEventQueue();

      expect(devices.registered, ['android:device-1']);
    });

    test('If signing out fails, the device is registered again', () async {
      await model.start();
      await pumpEventQueue();
      await model.unregister();

      model.resume();
      await pumpEventQueue();

      expect(devices.log, ['PUT device-1', 'DELETE device-1', 'PUT device-1']);
      expect(model.deviceId, 'device-1');
    });
  });
}
