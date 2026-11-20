import 'dart:ui' as ui;

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/core/widgets/aprop_logo.dart';
import 'package:aprop/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/auth/fake_auth_repository.dart';

Future<({int width, int height, Uint8List pixels})> _pixels(
  String asset,
) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  try {
    final frame = await codec.getNextFrame();
    try {
      final pixels = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      return (
        width: frame.image.width,
        height: frame.image.height,
        pixels: pixels!.buffer.asUint8List(),
      );
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

Color _dominantInk(Uint8List pixels) {
  final colors = <int, int>{};
  for (var offset = 0; offset < pixels.length; offset += 4) {
    if (pixels[offset + 3] < 250) continue;
    final key =
        ((pixels[offset] >> 4) << 8) |
        ((pixels[offset + 1] >> 4) << 4) |
        (pixels[offset + 2] >> 4);
    colors.update(key, (count) => count + 1, ifAbsent: () => 1);
  }
  final key = colors.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  return Color.fromARGB(
    255,
    ((key >> 8) & 15) * 16 + 8,
    ((key >> 4) & 15) * 16 + 8,
    (key & 15) * 16 + 8,
  );
}

void main() {
  for (final screen in ['Inici', 'Login']) {
    testWidgets('$screen logo has no opaque background and readable main ink', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final child = screen == 'Inici'
          // El logotip de la capçalera d'Inici (#273).
          ? const Scaffold(body: SafeArea(child: APropLogo(height: 40)))
          : LoginScreen(repository: FakeAuthRepository());
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: child));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('AProp!'), findsOneWidget);
      final logo = tester.widget<Image>(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.semanticLabel == 'AProp!',
        ),
      );
      final image = await tester.runAsync(
        () => _pixels((logo.image as AssetImage).assetName),
      );
      final pixels = image!.pixels;
      for (final offset in [
        0,
        (image.width - 1) * 4,
        (image.height - 1) * image.width * 4,
        (image.width * image.height - 1) * 4,
      ]) {
        expect(
          pixels[offset + 3],
          0,
          reason: 'The logo must blend with its surface.',
        );
      }
      final ink = _dominantInk(pixels).computeLuminance();
      for (final surface in [AppTheme.cream, AppTheme.cardBackground]) {
        final background = surface.computeLuminance();
        final ratio = (background + .05) / (ink + .05);
        expect(
          ratio,
          greaterThanOrEqualTo(7),
          reason: 'The main logo lettering must remain clearly readable.',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
