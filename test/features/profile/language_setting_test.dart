import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/profile/presentation/screens/profile_settings_screen.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_profile_repositories.dart';
import 'profile_test_data.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => LocaleController.active = LocaleController.defaultLocale);

  testWidgets(
    'the whole app switches language as soon as the controller does',
    (tester) async {
      final controller = LocaleController();
      await tester.pumpWidget(
        APropApp(
          authRepository: DemoAuthRepository(),
          localeController: controller,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inicia sessió'), findsOneWidget);

      await controller.setLocale(const Locale('en'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Inicia sessió'), findsNothing);
    },
  );

  group('language selector in Settings', () {
    late FakeProfileSettingsRepository repository;
    late LocaleController controller;

    Future<void> pumpSettings(WidgetTester tester) async {
      repository = FakeProfileSettingsRepository();
      controller = LocaleController();
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => MaterialApp(
            locale: controller.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates:
                GlobalMaterialLocalizations.delegates +
                const [AppLocalizations.delegate],
            home: ProfileSettingsScreen(
              user: profileUser,
              repository: repository,
              localeController: controller,
              onBack: () {},
              onSignOut: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('changes the visible text at once and tells the account', (
      tester,
    ) async {
      await pumpSettings(tester);
      expect(find.text('Configuració'), findsOneWidget);
      expect(find.text('Idioma'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pump();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Configuració'), findsNothing);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Castellano'));
      await tester.pumpAndSettle();
      expect(find.text('Configuración'), findsOneWidget);
      expect(repository.languages, ['en', 'es']);
    });

    testWidgets('keeps the new language when the account cannot be updated', (
      tester,
    ) async {
      await pumpSettings(tester);
      repository.languageError = Exception('offline');

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(
        find.textContaining('couldn’t save it to your account'),
        findsOneWidget,
      );
    });
  });
}
