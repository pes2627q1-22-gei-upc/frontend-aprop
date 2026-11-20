import 'dart:async';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/profile/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/profile/fake_profile_repositories.dart';
import '../features/profile/profile_test_data.dart';

void main() {
  late DemoAuthRepository auth;
  setUp(() async {
    auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
  });

  Finder destination(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  Finder profileScroll() => find.descendant(
    of: find.byKey(const PageStorageKey('profile-scroll')),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );

  Future<void> pumpApp(
    WidgetTester tester, {
    FakeProfileRepository? profiles,
    bool waitForProfile = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      APropApp(authRepository: auth, profileRepository: profiles),
    );
    await tester.pumpAndSettle();
    await tester.tap(destination('Perfil'));
    if (waitForProfile) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Configuració'));
    await tester.pumpAndSettle();
  }

  Future<void> settingsScrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('profile-settings-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Created tab opens the shared detail and survives back and section switches',
    (tester) async {
      await pumpApp(tester);
      expect(find.text('Laia Soler'), findsOneWidget);
      expect(find.text('laiasoler'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Creats per mi'),
        200,
        scrollable: profileScroll(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Creats per mi'));
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('profile-activity-demo-theatre'));
      await tester.scrollUntilVisible(tile, 200, scrollable: profileScroll());
      await tester.pumpAndSettle();
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(tile).dy;
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      expect(find.text('M’hi apunto'), findsOneWidget);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(tile).dy, closeTo(before, 1));
      await tester.tap(destination('Mapa'));
      await tester.pumpAndSettle();
      await tester.tap(destination('Perfil'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('profile-activity-demo-jazz')),
        findsNothing,
      );
      expect(tile, findsOneWidget);
    },
  );

  testWidgets(
    'Edited details and preferences persist through sign-out without leaking to a new account',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Biografia'),
        'Cinema a Vic',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Municipi'),
        'Vic',
      );
      await tester.ensureVisible(find.text('Desar'));
      await tester.tap(find.text('Desar'));
      await tester.pumpAndSettle();
      expect(find.text('Cinema a Vic'), findsOneWidget);
      await openSettings(tester);
      final preference = find.byKey(
        const ValueKey('profile-preference-showMyPlans'),
      );
      await settingsScrollTo(tester, preference);
      await tester.tap(preference);
      await tester.pumpAndSettle();
      final leave = find.byKey(const ValueKey('profile-sign-out'));
      await settingsScrollTo(tester, leave);
      await tester.tap(leave);
      await tester.pumpAndSettle();
      expect(find.text('Inicia sessió'), findsOneWidget);
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      await tester.pumpAndSettle();
      await tester.tap(destination('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Cinema a Vic'), findsOneWidget);
      await openSettings(tester);
      await settingsScrollTo(tester, preference);
      expect(tester.widget<SwitchListTile>(preference).value, isTrue);
      await auth.signOut();
      await tester.pumpAndSettle();
      await auth.register(
        firstName: 'Pol',
        lastName: 'Vidal',
        username: 'pol',
        email: 'pol@example.test',
        password: 'Password1!',
      );
      await auth.checkEmailVerified();
      await tester.pumpAndSettle();
      await tester.tap(destination('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Pol Vidal'), findsOneWidget);
      expect(find.text('Cinema a Vic'), findsNothing);
      expect(find.text('340 / 500 XP'), findsNothing);
      await openSettings(tester);
      await settingsScrollTo(tester, preference);
      expect(tester.widget<SwitchListTile>(preference).value, isFalse);
    },
  );

  testWidgets(
    'Sharing copies only the username and remains within the profile navigator',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpApp(tester);
      await tester.tap(find.text('Compartir perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Copiar nom d’usuari'));
      await tester.pumpAndSettle();
      expect(copied, '@laiasoler');
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
    },
  );

  testWidgets('A late profile load cannot replace another account identity', (
    tester,
  ) async {
    final pending = Completer<UserProfile>();
    final profiles = FakeProfileRepository()
      ..onGet = (user) => user.id == 'demo-laiasoler'
          ? pending.future
          : Future.value(sampleProfile(user: user, empty: true));
    await pumpApp(tester, profiles: profiles, waitForProfile: false);
    await auth.signOut();
    await tester.pumpAndSettle();
    await auth.register(
      firstName: 'Pol',
      lastName: 'Vidal',
      username: 'pol',
      email: 'pol@example.test',
      password: 'Password1!',
    );
    await auth.checkEmailVerified();
    await tester.pumpAndSettle();
    await tester.tap(destination('Perfil'));
    await tester.pumpAndSettle();
    pending.complete(sampleProfile());
    await tester.pumpAndSettle();
    expect(find.text('Pol Vidal'), findsOneWidget);
    expect(find.text('Adam Ziani'), findsNothing);
    expect(find.text('pol'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
