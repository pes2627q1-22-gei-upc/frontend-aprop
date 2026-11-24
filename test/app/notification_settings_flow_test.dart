import 'dart:convert';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/notifications/data/demo_notification_repository.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/presentation/widgets/notification_card.dart';
import 'package:aprop/features/profile/data/http_profile_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../features/profile/backend_profile_fixture.dart';

void main() {
  testWidgets(
    'Confirmed delivery settings survive navigation and preserve received alerts and privacy',
    (tester) async {
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      final user = (await tester.runAsync(
        () => auth.authStateChanges().first,
      ))!;
      final activities = DemoActivityRepository();
      final inbox = DemoNotificationRepository(
        activityRepository: activities,
        now: () => DateTime(2026, 11, 21, 18),
      );
      final before = (await tester.runAsync(
        () => inbox.getNotifications(user.id),
      ))!;
      final reminder = before.firstWhere(
        (notice) => notice.type == NotificationType.reminder,
      );
      var allowed = [17, 29, 53, 103];
      var share = false;
      final writes = <Object?>[];
      final client = ApiClient(
        idToken: () async => 'fixture-token',
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer fixture-token');
          if (request.method == 'PATCH') {
            final change = jsonDecode(request.body) as Map<String, Object?>;
            writes.add(change);
            if (change['allowed-notif-types'] case final List values) {
              allowed = values.cast<int>();
            }
            if (change['show-plans'] case final bool value) share = value;
          }
          final Object result = switch (request.url.path) {
            '/users/me' => {
              ...backendProfile(account: user.id),
              'show-plans': share,
            },
            '/users/me/settings' => {
              'id': 42,
              'show-plans': share,
              'language': 'ca',
              'notification-before': '3 days',
              'allowed-notif-types': allowed,
            },
            '/notificationtypes' => [
              {'id': 17, 'name': 'Social'},
              {'id': 29, 'name': 'Recordatori'},
              {'id': 53, 'name': 'Recomanacio'},
              {'id': 103, 'name': 'Cancelacio'},
            ],
            _ => throw StateError('Unexpected settings endpoint'),
          };
          return http.Response.bytes(utf8.encode(jsonEncode(result)), 200);
        }),
      );
      addTearDown(client.close);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        APropApp(
          authRepository: auth,
          activityRepository: activities,
          notificationRepository: inbox,
          profileSettingsRepository: HttpProfileSettingsRepository(
            apiClient: client,
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder destination(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );
      await tester.tap(destination('Perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Configuració'));
      await tester.pumpAndSettle();
      final reminders = find.byKey(
        const ValueKey('profile-preference-reminders'),
      );
      await tester.scrollUntilVisible(
        reminders,
        180,
        scrollable: find.descendant(
          of: find.byKey(const PageStorageKey('profile-settings-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(reminders);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(reminders).value, isTrue);
      await tester.tap(reminders);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(reminders).value, isFalse);
      expect(writes, [
        {
          'allowed-notif-types': [17, 53, 103],
        },
      ]);
      expect(share, isFalse);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Configuració'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(reminders);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(reminders).value, isFalse);
      await tester.tap(destination('Avisos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recordatoris'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<NotificationCard>(find.byType(NotificationCard))
            .any((card) => card.notification.id == reminder.id),
        isTrue,
      );
      final after = (await tester.runAsync(
        () => inbox.getNotifications(user.id),
      ))!;
      expect(
        after.map((notice) => (notice.id, notice.isRead)),
        before.map((notice) => (notice.id, notice.isRead)),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
