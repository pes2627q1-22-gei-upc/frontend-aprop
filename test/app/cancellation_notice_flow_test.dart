import 'dart:convert';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/http_activity_repository.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/notifications/data/http_notification_repository.dart';
import 'package:aprop/features/notifications/data/notification_json_mapper.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../features/activities/backend_event_fixture.dart';
import '../features/activities/fake_enrollment_repository.dart';
import '../features/notifications/backend_notification_fixture.dart';

/// #47: who joined an activity hears in Avisos that it was cancelled.
void main() {
  test('The backend type «Cancelacio» is a cancellation notice', () {
    final types = notificationTypesFromJson([
      ...backendNotificationTypes,
      {'id': 5, 'name': 'Cancelacio'},
    ]);

    expect(types['5'], NotificationType.activityCancelled);
    expect(
      NotificationType.activityCancelled.category,
      NotificationCategory.reminders,
    );
  });

  testWidgets(
    'L’avís diu que s’ha cancel·lat i la fitxa ja no deixa apuntar-s’hi',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final notice = {
        ...backendNotification(1, type: 5),
        'notification-date': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
        'text': 'Activitat 7 s’ha cancel·lat.',
      };
      final api = ApiClient(
        idToken: () async => 'test-token',
        client: MockClient((request) async {
          final Object data = switch (request.url.path) {
            '/users/me' => backendOwnProfile(firebaseId: 'demo-laiasoler'),
            '/notificationtypes' => [
              ...backendNotificationTypes,
              {'id': 5, 'name': 'Cancelacio'},
            ],
            '/notifications/user/$backendUserId' => [notice],
            '/notifications/1' => notice,
            '/notifications/1/read' => {'message': 'notification 1 read'},
            '/events/7' => backendEvent(7),
            '/events' => [backendEvent(7)],
            _ => throw StateError('Unexpected endpoint ${request.url.path}'),
          };
          return http.Response.bytes(
            utf8.encode(jsonEncode(data)),
            200,
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
      await tester.pumpWidget(
        APropApp(
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
      await tester.tap(find.widgetWithText(NavigationDestination, 'Avisos'));
      await tester.pumpAndSettle();

      // Under «Recordatoris», with the activity's title.
      await tester.tap(
        find.byKey(const ValueKey('notification-filter-reminders')),
      );
      await tester.pumpAndSettle();
      final message = find.text('S’ha cancel·lat «Activitat 7».');
      expect(message, findsOneWidget);

      await tester.tap(message);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('activity-cancelled-badge')),
        findsWidgets,
      );
      expect(find.text('M’hi apunto'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
