import 'dart:convert';

import 'package:aprop/app/navigation/main_shell.dart';
import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/http_activity_repository.dart';
import 'package:aprop/features/activities/data/http_discovery_repository.dart';
import 'package:aprop/features/activities/data/http_enrollment_repository.dart';
import 'package:aprop/features/assistant/data/demo_assistant_repository.dart';
import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/notifications/data/demo_notification_repository.dart';
import 'package:aprop/features/ratings/data/demo_rating_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_repository.dart';
import 'package:aprop/features/profile/data/demo_profile_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../features/activities/backend_event_fixture.dart';
import '../features/profile/backend_profile_fixture.dart';

void main() {
  testWidgets(
    'HTTP feed, paginated search, detail and Inici share confirmed enrollment and navigation',
    (tester) async {
      final enrolled = <int>{};
      final pages = <String>[];
      var writes = 0;
      Map<String, Object?> event(int id) => {
        ...backendEvent(id),
        'title': 'Jazz $id',
        'start-date': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
        'images': 'assets/images/jazz_al_parc.jpg',
      };
      final client = ApiClient(
        idToken: () async => 'fixture-token',
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer fixture-token');
          expect(request.headers.containsKey('X-User-ID'), isFalse);
          final path = request.url.path;
          Object body;
          switch (path) {
            case '/users/me':
              body = backendProfile(account: 'fixture-account');
            case '/preferences':
              body = [
                {
                  'category-id': 1,
                  'category-name': 'agenda:categories/musica',
                  'weight': 1.2,
                },
              ];
            case '/events/recommended':
              body = [event(7)];
            case '/events/popular':
              body = [event(8)];
            case '/events/search':
              final page = request.url.queryParameters['pageNum']!;
              pages.add(page);
              body = {
                'query': 'jazz',
                'page-num': int.parse(page),
                'page-size': 2,
                'total': 3,
                'events': [
                  for (final id in page == '0' ? [7, 8] : [9]) event(id),
                ],
              };
            case '/events':
              body = [event(7), event(8), event(9)];
            case '/categories':
              body = [];
            case '/users/$profileServerId/events':
              body = [for (final id in enrolled) event(id)];
            case '/events/7/signup':
              if (request.method == 'POST') {
                enrolled.add(7);
                writes++;
              }
              body = request.method == 'POST'
                  ? {'user-id': profileServerId, 'event-id': 7, 'created': true}
                  : {
                      'event-id': 7,
                      'is-enrolled': enrolled.contains(7),
                      'enrolled-count': enrolled.length,
                    };
            case '/events/9/signup':
              body = {'event-id': 9, 'is-enrolled': false, 'enrolled-count': 0};
            case '/events/7':
              body = event(7);
            case '/events/9':
              body = event(9);
            default:
              return http.Response('Not found: $path', 404);
          }
          return http.Response.bytes(
            utf8.encode(jsonEncode(body)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);
      final catalogue = HttpActivityRepository(apiClient: client);
      final enrollment = HttpEnrollmentRepository(apiClient: client);
      addTearDown(enrollment.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MainShell(
            user: const AppUser(
              id: 'fixture-account',
              serverId: profileServerId,
              email: 'fixture@example.test',
              firstName: 'Test',
              lastName: 'User',
              username: 'test_user',
              emailVerified: true,
            ),
            onSignOut: () async {},
            activityRepository: catalogue,
            enrollmentRepository: enrollment,
            discoveryRepository: HttpDiscoveryRepository(
              apiClient: client,
              searchPageSize: 2,
            ),
            ratingRepository: DemoRatingRepository(),
            assistantRepository: DemoAssistantRepository(
              activityRepository: catalogue,
            ),
            notificationRepository: DemoNotificationRepository(
              activityRepository: catalogue,
            ),
            profileRepository: DemoProfileRepository(
              activityRepository: catalogue,
            ),
            profileSettingsRepository: DemoProfileSettingsRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder destination(String text) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(text),
      );
      await tester.tap(destination('Descobreix'));
      await tester.pumpAndSettle();
      expect(find.text('Segons els teus interessos'), findsOneWidget);
      final recommended = find.byKey(const ValueKey('discover-recommended-7'));
      final join = find.descendant(
        of: recommended,
        matching: find.text('M’hi apunto'),
      );
      await tester.ensureVisible(join);
      await tester.pumpAndSettle();
      await tester.tap(join);
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(
        find.descendant(of: recommended, matching: find.text('Apuntat')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('discover-search')),
        -250,
        scrollable: find.descendant(
          of: find.byKey(const PageStorageKey('discover-feed')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('discover-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('activity-search-input')),
        'jazz',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('3 activitats trobades'), findsOneWidget);
      final scroll = find.descendant(
        of: find.byKey(const PageStorageKey('activity-search-results-jazz')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Carregar més activitats'),
        250,
        scrollable: scroll,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carregar més activitats'));
      await tester.pumpAndSettle();
      expect(pages, ['0', '1']);
      await tester.scrollUntilVisible(
        find.text('Jazz 9'),
        250,
        scrollable: scroll,
      );
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.text('Jazz 9')).dy;
      await tester.tap(find.text('Jazz 9'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Jazz 9')).dy, closeTo(before, 1));
      await tester.tap(destination('Inici'));
      await tester.pumpAndSettle();
      // Inici and search use the same enrollment state, even on distinct routes.
      expect(enrolled, {7});
      expect(find.text('Apuntat'), findsOneWidget);
      expect(writes, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
