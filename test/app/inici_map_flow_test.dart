import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  testWidgets('«Crear activitat» puja per sobre de la targeta del mapa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    await tester.pumpWidget(APropApp(authRepository: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    final button = find.byType(FloatingActionButton);
    final restingTop = tester.getTopLeft(button).dy;

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    map.markers.singleWhere((m) => m.markerId.value == 'demo-jazz').onTap!();
    await tester.pumpAndSettle();

    final cardTop = tester.getTopLeft(find.byType(Card).last).dy;
    expect(tester.getBottomLeft(button).dy, lessThan(cardTop));
    expect(tester.getTopLeft(button).dy, lessThan(restingTop));

    await tester.tap(find.byTooltip('Tancar'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(button).dy, restingTop);

    // Tornar a obrir la mateixa targeta també el fa pujar.
    tester
        .widget<GoogleMap>(find.byType(GoogleMap))
        .markers
        .singleWhere((m) => m.markerId.value == 'demo-jazz')
        .onTap!();
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(button).dy,
      lessThan(tester.getTopLeft(find.byType(Card).last).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
