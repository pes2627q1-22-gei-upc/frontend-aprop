import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aprop/app/aprop_app.dart';

void main() {
  testWidgets('Mostra les activitats de demostració', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const APropApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('AProp!'), findsOneWidget);
    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);
    expect(
      tester.getTopLeft(find.widgetWithText(OutlinedButton, 'Categories')).dy,
      tester.getTopLeft(find.widgetWithText(OutlinedButton, 'Dates')).dy,
    );

    final headerPosition = tester.getTopLeft(find.bySemanticsLabel('AProp!'));
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.bySemanticsLabel('AProp!')), headerPosition);
    expect(
      find.text('Teatre sota les estrelles').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Permet anar a Agenda i tornar a la llista', (tester) async {
    await tester.pumpWidget(const APropApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Agenda'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Agenda'), findsOneWidget);
    expect(find.text('Els teus plans culturals').hitTestable(), findsOneWidget);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Inici'));
    await tester.pumpAndSettle();

    expect(find.text('Jazz al parc').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
