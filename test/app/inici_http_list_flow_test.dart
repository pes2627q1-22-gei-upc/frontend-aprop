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
      await tester.tap(find.byTooltip('Netejar tots els filtres'));
      await tester.pumpAndSettle();
      expect(queries.last.containsKey('filterCategory'), isFalse);
      expect(queries.last['pageNum'], '0');
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
