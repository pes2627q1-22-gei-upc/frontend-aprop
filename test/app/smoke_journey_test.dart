import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'smoke_journey.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => LocaleController.active = LocaleController.defaultLocale);

  testWidgets(
    'Smoke journey (VM): accés, cerca, detall, inscripció, pestanyes, idioma i tancament',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await runAppSmokeJourney(tester);
    },
  );
}
