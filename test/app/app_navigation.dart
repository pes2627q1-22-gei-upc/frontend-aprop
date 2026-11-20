import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Obre la pestanya del mapa i la llista d'activitats. Des de la #273, en
/// entrar a l'app es veu Inici (les recomanacions de Descobreix).
Future<void> openMapTab(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, 'Mapa'));
  await tester.pumpAndSettle();
}
