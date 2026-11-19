import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

/// Holds the UI language. Changing it rebuilds the app at once and is stored
/// locally; syncing with the account is the settings screen's job.
class LocaleController extends ChangeNotifier {
  LocaleController({Locale? initial}) : _locale = initial ?? defaultLocale;

  static const defaultLocale = Locale('ca');
  static const _key = 'ui-language';

  /// Locale for code that has no [BuildContext] (view models, formatters).
  // shortcut: global, mirrors the last controller created; fine for one app.
  static Locale active = defaultLocale;

  Locale _locale;
  Locale get locale => _locale;

  /// Reads the stored language; falls back to Catalan if absent or unknown.
  Future<void> load() async {
    try {
      final code = (await SharedPreferences.getInstance()).getString(_key);
      final stored = AppLocalizations.supportedLocales
          .where((l) => l.languageCode == code)
          .firstOrNull;
      _apply(stored ?? defaultLocale);
    } catch (_) {
      _apply(_locale);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _apply(locale);
    try {
      await (await SharedPreferences.getInstance()).setString(
        _key,
        locale.languageCode,
      );
    } catch (_) {
      // The language stays applied for this run even if it can't be stored.
    }
  }

  void _apply(Locale locale) {
    _locale = locale;
    active = locale;
    notifyListeners();
  }
}

/// Exposes the [LocaleController] to the widget tree.
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LocaleScope>()?.notifier;
}

extension AppL10nContext on BuildContext {
  /// Localized strings; Catalan if the tree has no localization delegates.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ??
      lookupAppLocalizations(LocaleController.active);
}

/// Localized strings outside the widget tree.
AppLocalizations get currentL10n =>
    lookupAppLocalizations(LocaleController.active);
