import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Color del punt «ets aquí». El dona AppTheme.
class UserLocationTheme extends ThemeExtension<UserLocationTheme> {
  const UserLocationTheme({required this.dot});

  final Color dot;

  @override
  UserLocationTheme copyWith({Color? dot}) =>
      UserLocationTheme(dot: dot ?? this.dot);

  @override
  UserLocationTheme lerp(covariant UserLocationTheme? other, double t) {
    if (other == null) return this;
    return UserLocationTheme(dot: Color.lerp(dot, other.dot, t)!);
  }
}

/// Diàmetre, en píxels lògics, del punt «ets aquí».
const userLocationDotSize = 22.0;

/// Dibuixa el punt «ets aquí»: un cercle [fill] amb vora [border]. És la
/// mateixa imatge a la web i al mòbil, perquè a la web Google no dibuixa el
/// punt blau del mòbil.
Future<BitmapDescriptor> drawUserLocationIcon({
  required Color fill,
  required Color border,
  required double devicePixelRatio,
}) async {
  final pixels = (userLocationDotSize * devicePixelRatio).ceil();
  final radius = pixels / 2;
  final center = Offset(radius, radius);

  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..drawCircle(center, radius, Paint()..color = border)
    ..drawCircle(center, radius - 4 * devicePixelRatio, Paint()..color = fill);

  final image = await recorder.endRecording().toImage(pixels, pixels);
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return BytesMapBitmap(
      png!.buffer.asUint8List(),
      width: userLocationDotSize,
      height: userLocationDotSize,
    );
  } finally {
    image.dispose();
  }
}
