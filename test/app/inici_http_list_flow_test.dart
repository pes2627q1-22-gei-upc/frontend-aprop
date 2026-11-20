import 'dart:convert';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/data/http_activity_repository.dart';
import 'package:aprop/features/activities/presentation/screens/activities_screen.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_view_model.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../features/activities/backend_event_fixture.dart';
import '../features/activities/fake_enrollment_repository.dart';
import 'app_navigation.dart';

/// The map only shows activities with coordinates.
Map<String, Object?> located(Map<String, Object?> event) => {
  ...event,
  'latitude': 41.39,
  'longitude': 2.17,
};

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
                    ...located(backendEvent(999)),
                    'categories': ['agenda:ambits/concerts'],
                  }
                else
                  located(backendEvent(1)),
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
      // El resultat filtrat pel servidor arriba al mapa.
      expect(markerIds(tester), {'999'});
      await tester.tap(find.byTooltip('Netejar tots els filtres'));
      await tester.pumpAndSettle();
      expect(queries.last.containsKey('filterCategory'), isFalse);
      expect(queries.last['pageNum'], '0');
      expect(markerIds(tester), {'1'});
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'HTTP fallback list starts at zero, appends a page and returns from detail to its position',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pages = <String?>[];
      final model = ActivitiesViewModel(
        repository: HttpActivityRepository(
          apiClient: ApiClient(
            client: MockClient((request) async {
              final page = request.url.queryParameters['pageNum'];
              pages.add(page);
              final body = page == '0'
                  ? List.generate(50, (index) => backendEvent(index + 2))
                  : [backendEvent(52)];
              return http.Response.bytes(
                utf8.encode(jsonEncode(body)),
                200,
                headers: {'content-type': 'application/json'},
              );
            }),
          ),
        ),
      );
      final enrollment = EnrollmentViewModel(
        userId: 'user',
        repository: FakeEnrollmentRepository(),
      )..load();
      addTearDown(model.dispose);
      addTearDown(enrollment.dispose);
      await model.load();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          navigatorKey: navigator,
          home: Scaffold(
            body: ActivitiesScreen(
              viewModel: model,
              enrollmentViewModel: enrollment,
              // Stand-in for the detail route that MainShell pushes.
              onActivitySelected: (id) => navigator.currentState!.push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(body: Text('Detall $id')),
                ),
              ),
              // Without Google Maps the list takes the map's place (#274).
              googleMapsAvailable: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(pages, ['0', '1']);

      await tester.scrollUntilVisible(
        find.text('Activitat 52'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      final offset = tester.widget<ListView>(list).controller!.offset;
      await tester.tap(find.text('Activitat 52'));
      await tester.pumpAndSettle();
      expect(find.text('Detall 52'), findsOneWidget);

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(tester.widget<ListView>(list).controller!.offset, offset);
      expect(find.text('Activitat 52').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
