import 'dart:convert';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/core/network/api_client.dart';
import 'package:aprop/features/activities/presentation/screens/create_activity_screen.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/profile/data/http_profile_repository.dart';
import 'package:aprop/features/profile/data/http_profile_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../features/profile/backend_profile_fixture.dart';

void main() {
  testWidgets(
    'Confirmed HTTP identity and privacy survive navigation and feed event creation',
    (tester) async {
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      final user = (await tester.runAsync(
        () => auth.authStateChanges().first,
      ))!;
      var profile = backendProfile(account: user.id);
      final writes = <Map<String, Object?>>[];
      final client = ApiClient(
        idToken: () async => 'fixture-token',
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer fixture-token');
          if (request.url.path == '/users/me') {
            if (request.method == 'PATCH') {
              final changes = jsonDecode(request.body) as Map<String, Object?>;
              writes.add(changes);
              profile = {...profile, ...changes};
            }
            return http.Response(
              jsonEncode(profile),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (request.url.path == '/users/me/created-events') {
            return http.Response('[]', 200);
          }
          return http.Response('Not found', 404);
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
          profileRepository: HttpProfileRepository(apiClient: client),
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
      expect(find.text('Maria Soler'), findsOneWidget);
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom'),
        'Maria Casals',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom d’usuari'),
        'maria_c',
      );
      await tester.ensureVisible(find.text('Desar'));
      await tester.tap(find.text('Desar'));
      await tester.pumpAndSettle();
      expect(find.text('maria_c'), findsOneWidget);
      await tester.tap(find.text('Compartir perfil'));
      await tester.pumpAndSettle();
      expect(find.text('@maria_c'), findsOneWidget);
      await tester.tap(find.text('Cancel·lar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Configuració'));
      await tester.pumpAndSettle();
      final preference = find.byKey(
        const ValueKey('profile-preference-showMyPlans'),
      );
      await tester.ensureVisible(preference);
      await tester.tap(preference);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(preference).value, isTrue);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Configuració'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(preference);
      expect(tester.widget<SwitchListTile>(preference).value, isTrue);
      expect(writes, [
        {
          'name': 'Maria Casals',
          'username': 'maria_c',
          'biography': 'Teatre i concerts',
        },
        {'show-plans': true},
      ]);
      await tester.tap(destination('Inici'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear activitat'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CreateActivityScreen>(find.byType(CreateActivityScreen))
            .creator
            .name,
        'Maria Casals',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
