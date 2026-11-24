import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Block from profile → own friends/count → Settings blocked users → unblock without restoring friendship',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      await tester.pumpWidget(APropApp(authRepository: auth));
      await tester.pumpAndSettle();
      final nav = find.byType(NavigationBar);
      await tester.tap(find.descendant(of: nav, matching: find.text('Perfil')));
      await tester.pumpAndSettle();
      final count = find.byKey(const ValueKey('profile-friends-count'));
      await tester.tap(count);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('friend-demo-person-julia')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('public-profile-friend-options')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bloquejar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-user-block')));
      await tester.pumpAndSettle();
      expect(find.text('Has bloquejat aquest usuari.'), findsOneWidget);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('friend-demo-person-julia')),
        findsNothing,
      );
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: count, matching: find.text('13')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Configuració'));
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('settings-blocked-users'));
      await tester.ensureVisible(tile);
      expect(
        find.descendant(of: tile, matching: find.text('1')),
        findsOneWidget,
      );
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('blocked-user-demo-person-julia')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('blocked-user-demo-person-julia')),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'juliariera'), findsOneWidget);
      expect(find.text('Has bloquejat aquest usuari.'), findsOneWidget);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('blocked-user-demo-person-julia')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('unblock-user-demo-person-julia')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-user-block')));
      await tester.pumpAndSettle();
      expect(find.text('No tens usuaris bloquejats'), findsOneWidget);
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: tile, matching: find.text('0')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Tornar enrere'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: count, matching: find.text('13')),
        findsOneWidget,
      );
      expect(tester.widget<NavigationBar>(nav).selectedIndex, 4);
      expect(tester.takeException(), isNull);
    },
  );
}
