import 'dart:convert';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/http_activity_repository.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/notifications/data/http_notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../features/activities/backend_event_fixture.dart';
import '../features/activities/fake_enrollment_repository.dart';
import '../features/notifications/backend_notification_fixture.dart';

void main() {
  testWidgets(
    'HTTP read failure retries, opens the shared detail and survives a new inbox instance',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final received = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toIso8601String();
      var read = false;
      var fail = true;
      var writes = 0;
      final api = ApiClient(
        idToken: () async => 'test-token',
        client: MockClient((request) async {
          Object data;
          var status = 200;
          final notice = {
            ...backendNotification(1, type: 83, read: read),
            'notification-date': received,
          };
          switch (request.url.path) {
            case '/users/me':
              data = backendOwnProfile(firebaseId: 'demo-laiasoler');
            case '/notificationtypes':
              data = backendNotificationTypes;
            case '/notifications/user/$backendUserId':
              data = [notice];
            case '/notifications/1':
              data = notice;
            case '/notifications/1/read':
              expect(request.method, 'POST');
              writes++;
              if (fail) {
                status = 503;
                data = {'error': 'offline'};
              } else {
                read = true;
                data = {'message': 'notification 1 read'};
              }
            case '/events/7':
              data = backendEvent(7);
            case '/events':
              data = [backendEvent(7)];
            default:
              throw StateError('Unexpected endpoint ${request.url.path}');
          }
          return http.Response.bytes(
            utf8.encode(jsonEncode(data)),
            status,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(api.close);
      final activities = HttpActivityRepository(apiClient: api);
      final enrollments = FakeEnrollmentRepository();
      addTearDown(enrollments.dispose);
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      Future<void> pump(int instance) async {
        await tester.pumpWidget(
          APropApp(
            key: ValueKey(instance),
            authRepository: auth,
            activityRepository: activities,
            enrollmentRepository: enrollments,
            notificationRepository: HttpNotificationRepository(
              apiClient: api,
              activityRepository: activities,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Avisos'),
          ),
        );
        await tester.pumpAndSettle();
        final chip = find.byKey(
          const ValueKey('notification-filter-recommendations'),
        );
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }

      await pump(1);
      final message = find.text('“Activitat 7” et pot interessar.');
      await tester.tap(message);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Avisos'), findsOneWidget);
      expect(
        find.text(
          'No hem pogut marcar l’avís com a llegit. Torna-ho a provar.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-unread-1')),
        findsOneWidget,
      );
      fail = false;
      await tester.tap(message);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
      expect(find.text('Activitat 7'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(enrollments.enrolledRequests, isEmpty);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('notification-filter-recommendations')),
            )
            .selected,
        isTrue,
      );
      expect(find.byKey(const ValueKey('notification-unread-1')), findsNothing);
      await pump(2);
      expect(message, findsOneWidget);
      expect(find.byKey(const ValueKey('notification-unread-1')), findsNothing);
      expect(writes, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
