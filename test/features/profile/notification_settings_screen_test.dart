import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/profile/models/notification_preferences.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:aprop/features/profile/presentation/screens/profile_settings_screen.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_profile_repositories.dart';
import 'profile_test_data.dart';

Finder _control(ProfilePreference type) =>
    find.byKey(ValueKey('profile-preference-${type.name}'));

Future<void> _pump(
  WidgetTester tester,
  FakeProfileSettingsRepository repository, {
  String locale = 'ca',
  double scale = 1,
  bool settle = true,
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
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
  for (final locale in ['ca', 'es', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Four real, independent and accessible controls: $locale ×$scale',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = FakeProfileSettingsRepository();
          await _pump(tester, repository, locale: locale, scale: scale);
          final handle = tester.ensureSemantics();
          for (final type in NotificationPreferences.types) {
            final control = _control(type);
            await _show(tester, control);
            final before = tester.widget<SwitchListTile>(control).value;
            final semantics = tester.getSemantics(control).getSemanticsData();
            expect(
              semantics.flagsCollection.isToggled,
              before ? Tristate.isTrue : Tristate.isFalse,
            );
            expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
            await tester.tap(control);
            await tester.pumpAndSettle();
            expect(tester.widget<SwitchListTile>(control).value, !before);
          }
          handle.dispose();
          expect(
            repository.notificationUpdates
                .map((change) => change.preference)
                .toSet(),
            NotificationPreferences.types,
          );
          expect(repository.updates, isEmpty); // Plan sharing was not modified.
          expect(
            find.byKey(const ValueKey('profile-preference-friendActivity')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('profile-preference-friendRequests')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('A failed write keeps the confirmed switch and retries inline', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeProfileSettingsRepository();
    await _pump(tester, repository);
    final social = _control(ProfilePreference.social);
    await _show(tester, social);
    final l10n = AppLocalizations.of(tester.element(social))!;
    final pending = Completer<NotificationPreferences>();
    repository.onUpdateNotification = (_, _, _) => pending.future;
    await tester.tap(social);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(social).value, isTrue);
    expect(tester.widget<SwitchListTile>(social).onChanged, isNull);
    expect(find.text(l10n.settingsSavingChange), findsOneWidget);
    pending.completeError(StateError('Server did not persist the change'));
    await tester.pumpAndSettle();
    final retry = find.byKey(const ValueKey('retry-preference'));
    await _show(tester, retry);
    expect(find.text(l10n.settingsSaveError), findsOneWidget);
    repository.onUpdateNotification = null;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(social).value, isFalse);
    expect(repository.notificationUpdates.map((change) => change.enabled), [
      false,
      false,
    ]);
    expect(retry, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Loading failures are isolated and do not display invented off switches',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeProfileSettingsRepository()
        ..onGetNotifications = (_) async => throw StateError('Offline');
      await _pump(tester, repository);
      final privacy = _control(ProfilePreference.showMyPlans);
      await _show(tester, privacy);
      expect(tester.widget<SwitchListTile>(privacy).onChanged, isNotNull);
      expect(_control(ProfilePreference.social), findsNothing);
      final retry = find.byKey(const ValueKey('retry-notification-settings'));
      await _show(tester, retry);
      repository.onGetNotifications = null;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      await _show(tester, _control(ProfilePreference.social));
      expect(
        tester.widget<SwitchListTile>(_control(ProfilePreference.social)).value,
        isTrue,
      );
      expect(repository.notificationUpdates, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Switching accounts ignores the old pending notification response',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeProfileSettingsRepository();
      await _pump(tester, repository);
      final social = _control(ProfilePreference.social);
      await _show(tester, social);
      final pending = Completer<NotificationPreferences>();
      repository.onUpdateNotification = (_, _, _) => pending.future;
      await tester.tap(social);
      await tester.pump();
      await _pump(
        tester,
        repository,
        user: const AppUser(
          id: 'other-account',
          email: 'person@example.test',
          firstName: 'Persona',
          lastName: 'Exemple',
          emailVerified: true,
        ),
      );
      pending.complete(
        repository.notifications.withPreference(
          ProfilePreference.social,
          false,
        ),
      );
      await tester.pumpAndSettle();
      await _show(tester, social);
      expect(tester.widget<SwitchListTile>(social).value, isTrue);
      expect(repository.notificationUsers, ['user-a', 'other-account']);
      expect(tester.takeException(), isNull);
    },
  );
}
