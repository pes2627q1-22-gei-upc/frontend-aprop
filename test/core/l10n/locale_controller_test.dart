import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => LocaleController.active = LocaleController.defaultLocale);

  test('starts in Catalan and marks initial selection needed when nothing was stored', () async {
    final controller = LocaleController();
    await controller.load();

    expect(controller.locale, const Locale('ca'));
    expect(controller.needsInitialSelection, isTrue);
  });

  test('previewLocale updates immediately without persisting or clearing initial selection', () async {
    final controller = LocaleController();
    await controller.load();
    expect(controller.needsInitialSelection, isTrue);

    controller.previewLocale(const Locale('en'));
    expect(controller.locale, const Locale('en'));
    expect(LocaleController.active, const Locale('en'));
    expect(controller.needsInitialSelection, isTrue);

    // Restarting without confirming still requires initial selection.
    final restarted = LocaleController();
    await restarted.load();
    expect(restarted.locale, const Locale('ca'));
    expect(restarted.needsInitialSelection, isTrue);
  });

  test('setLocale notifies at once, clears initial selection, updates the active locale and persists', () async {
    final controller = LocaleController();
    await controller.load();
    expect(controller.needsInitialSelection, isTrue);

    var notifications = 0;
    controller.addListener(() => notifications++);

    final saving = controller.setLocale(const Locale('es'));
    expect(controller.locale, const Locale('es'));
    expect(LocaleController.active, const Locale('es'));
    expect(controller.needsInitialSelection, isFalse);
    expect(notifications, 1);
    await saving;

    final restarted = LocaleController();
    await restarted.load();
    expect(restarted.locale, const Locale('es'));
    expect(restarted.needsInitialSelection, isFalse);
  });

  test('confirming default Catalan persists and skips initial selection on restart', () async {
    final controller = LocaleController();
    await controller.load();
    expect(controller.needsInitialSelection, isTrue);

    await controller.setLocale(const Locale('ca'));
    expect(controller.needsInitialSelection, isFalse);

    final restarted = LocaleController();
    await restarted.load();
    expect(restarted.locale, const Locale('ca'));
    expect(restarted.needsInitialSelection, isFalse);
  });

  test('ignores unsupported languages, stored or requested', () async {
    SharedPreferences.setMockInitialValues({'ui-language': 'fr'});
    final controller = LocaleController();
    await controller.load();
    expect(controller.locale, const Locale('ca'));
    expect(controller.needsInitialSelection, isTrue);

    await controller.setLocale(const Locale('fr'));
    expect(controller.locale, const Locale('ca'));
    expect(controller.needsInitialSelection, isTrue);
    expect(LocaleController.supportedLocaleFor(' ES '), const Locale('es'));
    expect(LocaleController.supportedLocaleFor('fr'), isNull);
  });
}
