import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/activities/repositories/user_location_repository.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/activities/fake_enrollment_repository.dart';
import '../features/activities/fake_user_location_repository.dart';
import 'app_navigation.dart';

/// The map asks for the location when the Mapa tab is first shown, not when
/// the app opens (all the tabs are built at once).
void main() {
  testWidgets('El permís es demana en obrir la pestanya Mapa', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final location = FakeUserLocationRepository(access: LocationAccess.denied);
    final enrollments = FakeEnrollmentRepository();
    addTearDown(enrollments.dispose);
    final auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    await tester.pumpWidget(
      APropApp(
        authRepository: auth,
        enrollmentRepository: enrollments,
        userLocationRepository: location,
      ),
    );
    await tester.pumpAndSettle();
    expect(location.requests, 0);

    await openMapTab(tester);
    expect(location.requests, 1);

    // Only the first time.
    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();
    await openMapTab(tester);
    expect(location.requests, 1);
  });
}
