import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/app/smoke_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => LocaleController.active = LocaleController.defaultLocale);

  testWidgets(
    'Smoke journey (dispositiu): accés, cerca, detall, inscripció, pestanyes, idioma i tancament',
    runAppSmokeJourney,
  );
}
