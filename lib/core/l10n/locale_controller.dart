import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

/// Holds the UI language. Changing it rebuilds the app at once and is stored
/// locally; syncing with the account is handled on login and in Settings.
class LocaleController extends ChangeNotifier {
  LocaleController({Locale? initial, bool needsInitialSelection = false})
    : _locale = initial ?? defaultLocale,
      _needsSelection = needsInitialSelection;

  static const defaultLocale = Locale('ca');
  static const _key = 'ui-language';

  /// Locale for code that has no [BuildContext] (view models, formatters).
  // shortcut: global, mirrors the last controller created; fine for one app.
  static Locale active = defaultLocale;

  /// Returns the matching supported [Locale] for an ISO 639-1 [code], or
  /// `null` when absent or unsupported.
  static Locale? supportedLocaleFor(String? code) {
    if (code == null) return null;
    final normalized = code.trim().toLowerCase();
    return AppLocalizations.supportedLocales
        .where((l) => l.languageCode == normalized)
        .firstOrNull;
  }

  Locale _locale;
  Locale get locale => _locale;

  bool _needsSelection;

  /// True on the very first launch (after [load] finds no valid stored choice)
  /// until the user confirms a language via [setLocale].
  bool get needsInitialSelection => _needsSelection;

  /// Reads the stored language; falls back to Catalan if absent or unknown.
  /// Marks [needsInitialSelection] when no valid preference is stored yet.
  Future<void> load() async {
    try {
      final code = (await SharedPreferences.getInstance()).getString(_key);
      final stored = supportedLocaleFor(code);
      _needsSelection = stored == null;
      _apply(stored ?? defaultLocale);
    } catch (_) {
      _needsSelection = false;
      _apply(_locale);
    }
  }

  /// Skips the first-launch picker (e.g. an already signed-in user updating the
  /// app); the language is then taken from the profile sync.
  void skipInitialSelection() {
    if (!_needsSelection) return;
    _needsSelection = false;
    notifyListeners();
  }

  /// Applies [locale] immediately without persisting or closing the initial
  /// language picker (used for live preview while choosing on first launch).
  void previewLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _apply(locale);
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _needsSelection = false;
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
