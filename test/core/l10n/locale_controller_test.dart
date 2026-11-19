import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => LocaleController.active = LocaleController.defaultLocale);

  test('starts in Catalan when nothing was stored', () async {
    final controller = LocaleController();
    await controller.load();

    expect(controller.locale, const Locale('ca'));
  });

  test(
    'setLocale notifies at once, updates the active locale and persists',
    () async {
      final controller = LocaleController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      final saving = controller.setLocale(const Locale('es'));
      expect(controller.locale, const Locale('es'));
      expect(LocaleController.active, const Locale('es'));
      expect(notifications, 1);
      await saving;

      final restarted = LocaleController();
      await restarted.load();
      expect(restarted.locale, const Locale('es'));
    },
  );

  test('ignores unsupported languages, stored or requested', () async {
    SharedPreferences.setMockInitialValues({'ui-language': 'fr'});
    final controller = LocaleController();
    await controller.load();
    expect(controller.locale, const Locale('ca'));

    await controller.setLocale(const Locale('fr'));
    expect(controller.locale, const Locale('ca'));
  });
}
