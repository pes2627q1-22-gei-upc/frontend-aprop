import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final fromProfile in [false, true]) {
    testWidgets(
      'Reject from ${fromProfile ? 'profile' : 'notification'} preserves social filter, navigation and friend counters',
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
        await tester.tap(
          find.descendant(of: nav, matching: find.text('Avisos')),
        );
        await tester.pumpAndSettle();
        final filter = find.byKey(const ValueKey('notification-filter-social'));
        await tester.tap(filter);
        await tester.pumpAndSettle();
        final card = find.byKey(
          const ValueKey('notification-demo-request-notice'),
        );
        if (fromProfile) {
          await tester.tap(
            find.textContaining('Marc Vidal', findRichText: true).first,
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('public-profile-reject-friend')),
          );
          await tester.pumpAndSettle();
        } else {
          final reject = find.descendant(
            of: card,
            matching: find.text('Rebutjar'),
          );
          await tester.ensureVisible(reject);
          await tester.tap(reject);
          await tester.pumpAndSettle();
          expect(find.text('Sol·licitud rebutjada'), findsOneWidget);
          await tester.tap(
            find.textContaining('Marc Vidal', findRichText: true).first,
          );
          await tester.pumpAndSettle();
        }
        expect(find.widgetWithText(AppBar, 'marcvidal'), findsOneWidget);
        expect(find.text('Sol·licitud rebutjada'), findsOneWidget);
        expect(find.text('Afegeix com a amic'), findsOneWidget);
        expect(find.text('Acceptar'), findsNothing);
        expect(find.text('Rebutjar'), findsNothing);
        final count = find.byKey(const ValueKey('profile-friends-count'));
        expect(
          find.descendant(of: count, matching: find.text('3')),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Tornar enrere'));
        await tester.pumpAndSettle();
        expect(tester.widget<ChoiceChip>(filter).selected, isTrue);
        expect(find.text('Sol·licitud rebutjada'), findsOneWidget);
        await tester.tap(
          find.descendant(of: nav, matching: find.text('Perfil')),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: count, matching: find.text('14')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
