import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// Flutter executa aquesta funció abans de cada fitxer de proves.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // A les proves no hi ha cap mòbil on dibuixar Google Maps: el mapa es
  // substitueix per un espai buit. Els widgets `GoogleMap` continuen existint
  // i se'n poden comprovar els marcadors i cridar-ne els callbacks.
  GoogleMapsFlutterPlatform.instance = _FakeGoogleMapsPlatform();
  await testMain();
}

class _FakeGoogleMapsPlatform extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) {
    return const SizedBox.expand();
  }
}
