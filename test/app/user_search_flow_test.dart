import 'dart:convert';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/profile/data/http_public_profile_repository.dart';
import 'package:aprop/features/profile/data/http_user_search_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../features/profile/backend_profile_fixture.dart';
import 'app_navigation.dart';

String _id(int index) =>
    '22222222-2222-2222-2222-${index.toString().padLeft(12, '0')}';
http.Response _json(Object? value) => http.Response.bytes(
  utf8.encode(jsonEncode(value)),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  Future<DemoAuthRepository> auth() async {
    final auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    return auth;
  }

  void setSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'HTTP search → profile → back preserves query, page, mode and scroll',
    (tester) async {
      setSize(tester);
      final searches = <int>[];
      final calls = <String>[];
      final client = ApiClient(
        idToken: () async => 'search-token',
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer search-token');
          calls.add(request.url.path);
          if (request.url.path == '/users') {
            final page = int.parse(request.url.queryParameters['pageNum']!);
            searches.add(page);
            return _json({
              'query': 'maria',
              'page-num': page,
              'page-size': 20,
              'total': 21,
              'users': [
                for (
                  var i = page == 0 ? 1 : 21;
                  i <= (page == 0 ? 20 : 21);
                  i++
                )
                  {
                    'id': _id(i),
                    'username': 'maria$i',
                    'name': 'Maria $i',
                    'profile-picture': '',
                  },
              ],
            });
          }
          if (request.url.path == '/users/${_id(21)}') {
            return _json({
              ...backendProfile(),
              'id': _id(21),
              'username': 'maria21',
              'name': 'Maria 21',
              'is-friend': false,
              'plans-visible': false,
            });
          }
          if (request.url.path == '/users/${_id(21)}/created-events') {
            return _json([]);
          }
          throw StateError('Unexpected request: ${request.url}');
        }),
      );
      addTearDown(client.close);
      await tester.pumpWidget(
        APropApp(
          authRepository: await auth(),
          userSearchRepository: HttpUserSearchRepository(apiClient: client),
          publicProfileRepository: HttpPublicProfileRepository(
            apiClient: client,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('discover-search')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Persones'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('activity-search-input')),
        'maria',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('21 persones trobades'), findsOneWidget);
      final scrollable = find.descendant(
        of: find.byKey(const PageStorageKey('user-search-results-maria')),
        matching: find.byType(Scrollable),
      );
      final more = find.byKey(const ValueKey('users-load-more'));
      await tester.scrollUntilVisible(more, 400, scrollable: scrollable);
      await tester.tap(more);
      await tester.pumpAndSettle();
      final last = find.byKey(ValueKey('user-search-${_id(21)}'));
      await tester.scrollUntilVisible(last, 200, scrollable: scrollable);
      final offset = tester.state<ScrollableState>(scrollable).position.pixels;
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'maria21'), findsOneWidget);
      expect(find.text('Editar perfil'), findsNothing);
      expect(calls.where((path) => path.endsWith('/events')), isEmpty);

      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'maria',
      );
      expect(
        tester
            .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
            .selected,
        {false},
      );
      expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
      expect(last.hitTestable(), findsOneWidget);
      expect(searches, [0, 1]);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, 'Inici'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Cerca'), findsOneWidget);
      expect(last.hitTestable(), findsOneWidget);
      expect(searches, [0, 1]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'The own search result opens Perfil and keeps the search in Inici',
    (tester) async {
      setSize(tester);
      await tester.pumpWidget(APropApp(authRepository: await auth()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('discover-search')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Persones'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'laia');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('user-search-demo-laiasoler')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      expect(find.text('Editar perfil'), findsOneWidget);
      await tester.tap(find.widgetWithText(NavigationDestination, 'Inici'));
      await tester.pumpAndSettle();
      expect(find.text('@laiasoler'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'laia',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('People search also opens from Mapa and returns to its section', (
    tester,
  ) async {
    setSize(tester);
    await tester.pumpWidget(APropApp(authRepository: await auth()));
    await tester.pumpAndSettle();
    await openMapTab(tester);
    await tester.tap(find.byKey(const ValueKey('map-search')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Persones'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'marc');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('user-search-demo-person-marc')),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'marcvidal'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('@marcvidal'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'marc',
    );
    expect(tester.takeException(), isNull);
  });
}
