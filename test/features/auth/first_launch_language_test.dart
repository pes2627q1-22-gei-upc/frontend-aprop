import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/auth/presentation/screens/language_selection_screen.dart';
import 'package:aprop/features/interest_test/models/interest_question.dart';
import 'package:aprop/features/interest_test/repositories/interest_test_repository.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/fake_profile_repositories.dart';

class _RecordingInterestTestRepository implements InterestTestRepository {
  _RecordingInterestTestRepository({
    required this.localeController,
    this.completed = false,
  });

  final LocaleController localeController;
  final bool completed;
  final localesWhenFetched = <String>[];

  @override
  Future<InterestTestStatus> getTestStatus() async =>
      InterestTestStatus(completed: completed, prompted: completed);

  @override
  Future<void> markOnboardingPrompted() async {}

  @override
  Future<List<InterestQuestion>> getQuestions() async {
    localesWhenFetched.add(localeController.locale.languageCode);
    return const [
      InterestQuestion(
        eventId: 1,
        title: 'Event',
        description: 'Description',
        categories: ['Art'],
      ),
    ];
  }

  @override
  Future<void> submitAnswers(
    List<InterestAnswer> answers, {
    bool partial = false,
  }) async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => LocaleController.active = LocaleController.defaultLocale);

  void usePhoneSize(WidgetTester tester, [Size size = const Size(390, 844)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('First-launch language selection', () {
    testWidgets(
      'shows picker before login on first launch, previews live, persists, and never shows again',
      (tester) async {
        usePhoneSize(tester);
        final controller = LocaleController();
        await controller.load();

        await tester.pumpWidget(
          APropApp(
            authRepository: DemoAuthRepository(),
            localeController: controller,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LanguageSelectionScreen), findsOneWidget);
        expect(find.text('Tria el teu idioma'), findsOneWidget);
        expect(find.text('Inicia sessió'), findsNothing);

        // Selecting English updates the screen live before confirming.
        await tester.tap(find.byKey(const ValueKey('language-option-en')));
        await tester.pumpAndSettle();
        expect(find.text('Choose your language'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        expect(controller.needsInitialSelection, isTrue);

        // Confirming persists the choice and proceeds to LoginScreen in English.
        await tester.tap(
          find.byKey(const ValueKey('language-picker-continue')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LanguageSelectionScreen), findsNothing);
        expect(find.text('Sign in'), findsWidgets);
        expect(controller.locale, const Locale('en'));
        expect(controller.needsInitialSelection, isFalse);

        // Simulating a restart with the same SharedPreferences skips the picker.
        final restarted = LocaleController();
        await restarted.load();
        expect(restarted.needsInitialSelection, isFalse);
        expect(restarted.locale, const Locale('en'));

        await tester.pumpWidget(
          APropApp(
            authRepository: DemoAuthRepository(),
            localeController: restarted,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LanguageSelectionScreen), findsNothing);
        expect(find.text('Sign in'), findsWidgets);
      },
    );

    testWidgets(
      'confirming Catalan on first launch persists it so picker is not shown again',
      (tester) async {
        usePhoneSize(tester);
        final controller = LocaleController();
        await controller.load();

        await tester.pumpWidget(
          APropApp(
            authRepository: DemoAuthRepository(),
            localeController: controller,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('language-picker-continue')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Inicia sessió'), findsOneWidget);

        final restarted = LocaleController();
        await restarted.load();
        expect(restarted.needsInitialSelection, isFalse);
        expect(restarted.locale, const Locale('ca'));
      },
    );

    testWidgets(
      'skips picker on launch when a stored preference already exists',
      (tester) async {
        usePhoneSize(tester);
        SharedPreferences.setMockInitialValues({'ui-language': 'es'});
        final controller = LocaleController();
        await controller.load();

        await tester.pumpWidget(
          APropApp(
            authRepository: DemoAuthRepository(),
            localeController: controller,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LanguageSelectionScreen), findsNothing);
        expect(find.text('Inicia sesión'), findsOneWidget);
      },
    );

    testWidgets(
      'renders cleanly on narrow 320px screens with 2x text scaling and >=48px targets',
      (tester) async {
        usePhoneSize(tester, const Size(320, 640));
        final controller = LocaleController(needsInitialSelection: true);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2.0),
            ),
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => MaterialApp(
                theme: AppTheme.light,
                locale: controller.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: LanguageSelectionScreen(controller: controller),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (final code in ['ca', 'es', 'en']) {
          final option = find.byKey(ValueKey('language-option-$code'));
          expect(tester.getSize(option).height, greaterThanOrEqualTo(48));
          await tester.ensureVisible(option);
          await tester.tap(option);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        final continueBtn = find.byKey(
          const ValueKey('language-picker-continue'),
        );
        expect(tester.getSize(continueBtn).height, greaterThanOrEqualTo(48));
      },
    );
  });

  group('Post-login language synchronization', () {
    Future<DemoAuthRepository> signedInAuth() async {
      final auth = DemoAuthRepository();
      await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
      return auth;
    }

    testWidgets(
      'applies backend profile language after login before fetching interest test',
      (tester) async {
        usePhoneSize(tester);
        SharedPreferences.setMockInitialValues({'ui-language': 'en'});
        final controller = LocaleController();
        await controller.load();
        final settingsRepo = FakeProfileSettingsRepository()
          ..settings = const ProfileSettings(language: 'es');
        final interestRepo = _RecordingInterestTestRepository(
          localeController: controller,
          completed: false,
        );

        await tester.pumpWidget(
          APropApp(
            authRepository: await signedInAuth(),
            localeController: controller,
            profileSettingsRepository: settingsRepo,
            interestTestRepository: interestRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(controller.locale, const Locale('es'));
        expect(settingsRepo.languages, isEmpty);
        expect(interestRepo.localesWhenFetched, ['es']);
        expect(find.text('Test de intereses'), findsOneWidget);

        // Stored locally in SharedPreferences so restart stays in Spanish.
        final restarted = LocaleController();
        await restarted.load();
        expect(restarted.locale, const Locale('es'));
      },
    );

    testWidgets(
      'pushes local language to backend when profile has no language stored',
      (tester) async {
        usePhoneSize(tester);
        SharedPreferences.setMockInitialValues({'ui-language': 'en'});
        final controller = LocaleController();
        await controller.load();
        final settingsRepo = FakeProfileSettingsRepository()
          ..settings = const ProfileSettings(language: null);

        await tester.pumpWidget(
          APropApp(
            authRepository: await signedInAuth(),
            localeController: controller,
            profileSettingsRepository: settingsRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(controller.locale, const Locale('en'));
        expect(settingsRepo.languages, ['en']);
        expect(find.byType(NavigationBar), findsOneWidget);
      },
    );

    testWidgets(
      'does not block app entry when language sync fails and keeps local language',
      (tester) async {
        usePhoneSize(tester);
        SharedPreferences.setMockInitialValues({'ui-language': 'en'});
        final controller = LocaleController();
        await controller.load();
        final settingsRepo = FakeProfileSettingsRepository()
          ..onGet = (_) async => throw Exception('offline');

        await tester.pumpWidget(
          APropApp(
            authRepository: await signedInAuth(),
            localeController: controller,
            profileSettingsRepository: settingsRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(controller.locale, const Locale('en'));
        expect(find.byType(NavigationBar), findsOneWidget);
      },
    );

    testWidgets(
      'Profile Settings language switch stays in sync after first-launch selection',
      (tester) async {
        usePhoneSize(tester);
        final auth = DemoAuthRepository();
        final controller = LocaleController();
        await controller.load();
        final settingsRepo = FakeProfileSettingsRepository()
          ..settings = const ProfileSettings(language: null);

        await tester.pumpWidget(
          APropApp(
            authRepository: auth,
            localeController: controller,
            profileSettingsRepository: settingsRepo,
          ),
        );
        await tester.pumpAndSettle();

        // First launch: pick English and confirm.
        await tester.tap(find.byKey(const ValueKey('language-option-en')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('language-picker-continue')),
        );
        await tester.pumpAndSettle();

        // Sign in: local 'en' pushed to profile.
        await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
        await tester.pumpAndSettle();
        expect(settingsRepo.languages, ['en']);

        // Open Profile > Settings and switch to Spanish.
        await tester.tap(find.widgetWithText(NavigationDestination, 'Profile'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Castellano'));
        await tester.pumpAndSettle();

        expect(controller.locale, const Locale('es'));
        expect(find.text('Configuración'), findsOneWidget);
        expect(settingsRepo.languages, ['en', 'es']);

        final restarted = LocaleController();
        await restarted.load();
        expect(restarted.locale, const Locale('es'));
        expect(restarted.needsInitialSelection, isFalse);
      },
    );
  });
}
