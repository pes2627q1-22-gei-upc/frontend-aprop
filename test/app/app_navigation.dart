import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Obre la pestanya del mapa. Des de la #273, en entrar a l'app es veu Inici
/// (les recomanacions de Descobreix), i des de la #274 aquesta pestanya
/// només té el mapa.
Future<void> openMapTab(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, 'Mapa'));
  await tester.pumpAndSettle();
}

/// El mapa de la pestanya Mapa (a les proves, sense dibuix).
GoogleMap mapOf(WidgetTester tester) =>
    tester.widget<GoogleMap>(find.byType(GoogleMap));

/// Identificadors dels marcadors del mapa.
Set<String> markerIds(WidgetTester tester) => {
  for (final marker in mapOf(tester).markers) marker.markerId.value,
};

/// Toca el marcador de l'activitat [id] i n'obre la targeta.
Future<void> tapMarker(WidgetTester tester, String id) async {
  // Un toc al mapa just després d'un clic a sobre seu (un botó, un panell) es
  // pren pel mateix clic (DP-045): la persona no toca tan de pressa.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 600)),
  );
  mapOf(tester).markers.singleWhere((m) => m.markerId.value == id).onTap!();
  await tester.pumpAndSettle();
}

/// Tanca la targeta del marcador, si n'hi ha cap d'oberta.
Future<void> closeMapCard(WidgetTester tester) async {
  final close = find.byTooltip('Tancar');
  if (close.evaluate().isEmpty) return;
  await tester.tap(close);
  await tester.pumpAndSettle();
}

/// Mou el mapa a [target] amb [zoom], com si la persona l'hi hagués portat.
Future<void> zoomMapTo(WidgetTester tester, LatLng target, double zoom) async {
  mapOf(tester).onCameraMove!(CameraPosition(target: target, zoom: zoom));
  mapOf(tester).onCameraIdle!();
  await tester.pumpAndSettle();
}
