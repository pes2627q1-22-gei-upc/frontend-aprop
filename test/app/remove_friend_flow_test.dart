import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final fromProfile in [false, true]) {
    testWidgets(
      'Remove from ${fromProfile ? 'public profile' : 'own list'} updates own list, badge and counters',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = DemoAuthRepository();
        await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
        await tester.pumpWidget(APropApp(authRepository: auth));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Perfil'),
          ),
        );
        await tester.pumpAndSettle();
        final count = find.byKey(const ValueKey('profile-friends-count'));
        expect(
          find.descendant(of: count, matching: find.text('14')),
          findsOneWidget,
        );
        await tester.tap(count);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('friend-demo-person-julia')),
          findsOneWidget,
        );
        if (fromProfile) {
          await tester.tap(
            find.byKey(const ValueKey('friend-demo-person-julia')),
          );
          await tester.pumpAndSettle();
          expect(find.widgetWithText(AppBar, 'juliariera'), findsOneWidget);
          await tester.tap(
            find.byKey(const ValueKey('public-profile-friend-options')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Eliminar amistat'));
          await tester.pumpAndSettle();
        } else {
          await tester.tap(
            find.byKey(const ValueKey('remove-friend-demo-person-julia')),
          );
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey('confirm-remove-friend')));
        await tester.pumpAndSettle();
        if (fromProfile) {
          expect(find.text('Afegeix com a amic'), findsOneWidget);
          expect(
            find.descendant(of: count, matching: find.text('7')),
            findsOneWidget,
          );
          await tester.tap(find.byTooltip('Tornar enrere'));
          await tester.pumpAndSettle();
        }
        expect(
          find.byKey(const ValueKey('friend-demo-person-julia')),
          findsNothing,
        );
        expect(find.text('Encara no tens amics.'), findsOneWidget);
        await tester.tap(find.byTooltip('Tornar enrere'));
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: count, matching: find.text('13')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          4,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
