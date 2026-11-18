import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'activity_map_groups.dart';

/// Dibuixa el cercle d'un grup amb els colors de l'app: fons [fill], número
/// [textColor] i vora [border]. És la mateixa imatge a la web i al mòbil, en
/// lloc dels cercles blaus i vermells de Google.
Future<BitmapDescriptor> drawMapGroupIcon(
  String label, {
  required Color fill,
  required Color textColor,
  required Color border,
  required double devicePixelRatio,
}) async {
  final diameter = mapGroupDiameter(label);
  final pixels = (diameter * devicePixelRatio).ceil();
  final radius = pixels / 2;
  final center = Offset(radius, radius);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas
    ..drawCircle(center, radius, Paint()..color = border)
    ..drawCircle(center, radius - 3 * devicePixelRatio, Paint()..color = fill);
  final text = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: textColor,
        fontSize: 15 * devicePixelRatio,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  text.dispose();

  final image = await recorder.endRecording().toImage(pixels, pixels);
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return BytesMapBitmap(
      png!.buffer.asUint8List(),
      width: diameter,
      height: diameter,
    );
  } finally {
    image.dispose();
  }
}
