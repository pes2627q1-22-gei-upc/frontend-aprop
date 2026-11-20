import 'dart:convert';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/http_activity_repository.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../features/activities/backend_event_fixture.dart';
import '../features/activities/fake_enrollment_repository.dart';
import 'app_navigation.dart';

void main() {
  testWidgets(
    'Inici loads category options and applies/cancels real HTTP filters',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final queries = <Map<String, String>>[];
      final repository = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((request) async {
            Object body;
            if (request.url.path == '/categories') {
              body = [
                {'id': 71, 'name': 'agenda:ambits/concerts'},
              ];
            } else {
              final query = request.url.queryParameters;
              queries.add(query);
              body = [
                if (query.containsKey('filterCategory'))
                  {
                    ...backendEvent(999),
                    'categories': ['agenda:ambits/concerts'],
                  }
                else
                  backendEvent(1),
              ];
            }
            return http.Response.bytes(
              utf8.encode(jsonEncode(body)),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      await tester.pumpWidget(
        APropApp(
          authRepository: auth,
          activityRepository: repository,
          enrollmentRepository: FakeEnrollmentRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await openMapTab(tester);
      await tester.tap(
        find.byKey(const ValueKey('activities-filter-categories')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('activity-filter-category-Concerts')),
      );
      await tester.tap(find.byTooltip('Tancar el filtre'));
      await tester.pumpAndSettle();
      expect(
        queries.where((query) => query.containsKey('filterCategory')),
        isEmpty,
      );
      await tester.tap(
        find.byKey(const ValueKey('activities-filter-categories')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('activity-filter-category-Concerts')),
      );
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(queries.last['filterCategory'], '71');
      expect(queries.last['pageNum'], '0');
      expect(find.text('Activitat 999'), findsOneWidget);
      expect(find.text('Activitat 1'), findsNothing);
      await tester.tap(find.byTooltip('Netejar tots els filtres'));
      await tester.pumpAndSettle();
      expect(queries.last.containsKey('filterCategory'), isFalse);
      expect(queries.last['pageNum'], '0');
      expect(find.text('Activitat 1'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'HTTP list starts at zero, appends a page and returns from detail to its position',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pages = <String?>[];
      final details = <String>[];
      final repo = HttpActivityRepository(
        apiClient: ApiClient(
          client: MockClient((request) async {
            Object body;
            if (request.url.path == '/events') {
              final page = request.url.queryParameters['pageNum'];
              if (request.url.queryParameters['pageSize'] == '50') {
                pages.add(page);
              }
              body = page == '0'
                  ? List.generate(50, (index) => backendEvent(index + 2))
                  : [backendEvent(52)];
            } else {
              details.add(request.url.path);
              body = backendEvent(int.parse(request.url.pathSegments.last));
            }
            return http.Response.bytes(
              utf8.encode(jsonEncode(body)),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      await tester.pumpWidget(
        APropApp(
          authRepository: auth,
          activityRepository: repo,
          enrollmentRepository: FakeEnrollmentRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await openMapTab(tester);
      expect(find.text('Activitat 2'), findsOneWidget);
      final list = find.byKey(const PageStorageKey<String>('activities-list'));
      final scrollable = find.descendant(
        of: list,
        matching: find.byType(Scrollable),
      );
      final more = find.byKey(const ValueKey('activities-load-more'));
      await tester.scrollUntilVisible(
        more,
        800,
        scrollable: scrollable,
        maxScrolls: 80,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(more);
      await tester.pumpAndSettle();
      await tester.tap(more);
      await tester.pumpAndSettle();
      // Other section projections may also read the initial snapshot.
      expect(pages.first, '0');
      expect(pages.where((page) => page != '0'), ['1']);
      await tester.scrollUntilVisible(
        find.text('Activitat 52'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Activitat 52'));
      await tester.pumpAndSettle();
      final offset = tester.widget<ListView>(list).controller!.offset;
      await tester.tap(find.text('Activitat 52'));
      await tester.pumpAndSettle();
      expect(details.last, '/events/52');
      expect(find.text('Descripció de prova del servidor.'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(tester.widget<ListView>(list).controller!.offset, offset);
      expect(find.text('Activitat 52').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
