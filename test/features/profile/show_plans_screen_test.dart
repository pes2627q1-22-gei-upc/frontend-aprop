import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:aprop/features/profile/presentation/screens/profile_settings_screen.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_profile_repositories.dart';
import 'profile_test_data.dart';

const _controlKey = ValueKey('profile-preference-showMyPlans');
final _control = find.byKey(_controlKey);

Future<void> _pump(
  WidgetTester tester,
  FakeProfileSettingsRepository repository, {
  String locale = 'ca',
  double scale = 1,
  AppUser user = profileUser,
}) async {
  tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: ProfileSettingsScreen(
        user: user,
        repository: repository,
        onBack: () {},
        onSignOut: () async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ca', 'es', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Privacy is readable, tappable and not conveyed only by colour: $language ×$scale',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = FakeProfileSettingsRepository();
          await _pump(tester, repository, locale: language, scale: scale);
          await _show(tester, _control);
          final l10n = AppLocalizations.of(tester.element(_control))!;
          expect(find.text(l10n.settingsPlansPrivate), findsOneWidget);
          expect(tester.getSize(_control).height, greaterThanOrEqualTo(48));
          final handle = tester.ensureSemantics();
          final semantics = tester.getSemantics(_control).getSemanticsData();
          expect(semantics.flagsCollection.isToggled, Tristate.isFalse);
          expect(semantics.label, contains(l10n.settingsShowMyPlans));
          handle.dispose();
          await tester.tap(_control);
          await tester.pumpAndSettle();
          expect(tester.widget<SwitchListTile>(_control).value, isTrue);
          expect(find.text(l10n.settingsPlansShared), findsOneWidget);
          expect(repository.updates.single.enabled, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'A failed attempt to hide plans retains the confirmed value and retries without retoggling',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeProfileSettingsRepository()
        ..settings = const ProfileSettings(showMyPlans: true);
      await _pump(tester, repository);
      await _show(tester, _control);
      final l10n = AppLocalizations.of(tester.element(_control))!;
      final pending = Completer<ProfileSettings>();
      repository.onUpdate = (_, _, _) => pending.future;
      await tester.tap(_control);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(_control).value, isTrue);
      expect(tester.widget<SwitchListTile>(_control).onChanged, isNull);
      expect(find.text(l10n.settingsSavingChange), findsOneWidget);
      final handle = tester.ensureSemantics();
      expect(
        tester
            .getSemantics(_control)
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      handle.dispose();
      pending.completeError(StateError('Offline'));
      await tester.pumpAndSettle();
      final retry = find.byKey(const ValueKey('retry-preference'));
      await _show(tester, retry);
      expect(find.text(l10n.settingsSaveError), findsOneWidget);
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
      repository.onUpdate = null;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(repository.updates.map((c) => c.enabled), [false, false]);
      expect(tester.widget<SwitchListTile>(_control).value, isFalse);
      expect(find.text(l10n.settingsPlansPrivate), findsOneWidget);
      expect(retry, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'An unreadable setting is not shown as a private default; loading can be retried',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeProfileSettingsRepository()
        ..onGet = (_) async => throw StateError('Offline');
      await _pump(tester, repository);
      expect(_control, findsNothing);
      repository.onGet = (_) async => const ProfileSettings(showMyPlans: true);
      await tester.tap(find.text('Tornar-ho a provar'));
      await tester.pumpAndSettle();
      await _show(tester, _control);
      expect(tester.widget<SwitchListTile>(_control).value, isTrue);
      expect(repository.updates, isEmpty);
    },
  );

  testWidgets(
    'A late write from the old account cannot change the new account',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeProfileSettingsRepository();
      await _pump(tester, repository);
      await _show(tester, _control);
      final pending = Completer<ProfileSettings>();
      repository.onUpdate = (_, _, _) => pending.future;
      await tester.tap(_control);
      await tester.pump();
      await _pump(
        tester,
        repository,
        user: const AppUser(
          id: 'new-account',
          email: 'person@example.test',
          firstName: 'Persona',
          lastName: 'Exemple',
          emailVerified: true,
        ),
      );
      pending.complete(const ProfileSettings(showMyPlans: true));
      await tester.pumpAndSettle();
      await _show(tester, _control);
      expect(tester.widget<SwitchListTile>(_control).value, isFalse);
      expect(repository.users, ['user-a', 'new-account']);
      expect(tester.takeException(), isNull);
    },
  );
}
