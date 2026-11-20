import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/activities/fake_enrollment_repository.dart';

/// #54: the «Amics» counter opens the friends list, and each friend their
/// profile.
void main() {
  late FakeEnrollmentRepository enrollments;

  setUp(() => enrollments = FakeEnrollmentRepository());
  tearDown(() => enrollments.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    await tester.pumpWidget(
      APropApp(authRepository: auth, enrollmentRepository: enrollments),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Perfil'));
    await tester.pumpAndSettle();
  }

  Future<void> openFriends(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('profile-friends-count')).last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Amics'), findsOneWidget);
  }

  testWidgets('Els meus amics obren el seu perfil i els seus amics', (
    tester,
  ) async {
    await pumpApp(tester);
    await openFriends(tester);

    // Laia never appears as her own friend.
    expect(
      find.byKey(const ValueKey('friend-demo-person-julia')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('friend-demo-laiasoler')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('friend-demo-person-julia')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'juliariera'), findsOneWidget);

    // Júlia's friends: Laia, who opens her own Perfil tab.
    await openFriends(tester);
    await tester.tap(find.byKey(const ValueKey('friend-demo-laiasoler')));
    await tester.pumpAndSettle();
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 4);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Una persona sense amics mostra el missatge buit', (
    tester,
  ) async {
    await pumpApp(tester);
    // Marc's profile, from his friend request.
    await tester.tap(find.widgetWithText(NavigationDestination, 'Avisos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notification-filter-social')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.textContaining('Marc Vidal', findRichText: true).first,
    );
    await tester.pumpAndSettle();

    await openFriends(tester);
    expect(find.text('Marc Vidal encara no té amics.'), findsOneWidget);
  });
}
