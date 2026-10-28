import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/profile/data/profile_json_mapper.dart';
import 'package:aprop/features/profile/models/profile_capabilities.dart';
import 'package:aprop/features/profile/models/profile_settings.dart';
import 'package:aprop/features/profile/models/user_profile.dart';
import 'package:aprop/features/profile/presentation/screens/profile_screen.dart';
import 'package:aprop/features/profile/presentation/screens/profile_settings_screen.dart';
import 'package:aprop/features/profile/presentation/view_models/profile_view_model.dart';
import 'package:aprop/features/profile/presentation/widgets/profile_activity_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_profile_repositories.dart';
import 'backend_profile_fixture.dart' as backend;
import 'profile_test_data.dart';

void main() {
  late FakeProfileRepository profiles;
  late FakeProfileSettingsRepository settings;
  late ProfileViewModel model;
  String? opened;
  var settingsOpened = 0;
  var shares = 0;
  var signOuts = 0;
  setUp(() {
    profiles = FakeProfileRepository();
    settings = FakeProfileSettingsRepository();
    model = ProfileViewModel(user: profileUser, repository: profiles);
    opened = null;
    settingsOpened = 0;
    shares = 0;
    signOuts = 0;
  });
  tearDown(() => model.dispose());

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool configuration = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(scale > 1 ? 320 : 390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (!configuration) model.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: configuration
            ? ProfileSettingsScreen(
                user: profileUser,
                repository: settings,
                onBack: () {},
                onSignOut: () async {
                  signOuts++;
                },
              )
            : ProfileScreen(
                viewModel: model,
                onSettingsPressed: () => settingsOpened++,
                onSharePressed: () => shares++,
                onActivitySelected: (id) => opened = id,
              ),
      ),
    );
    await tester.pump();
  }

  Finder verticalScroll() => find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: verticalScroll());
    await tester.pumpAndSettle();
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Backend identity is editable and updates only after confirmation without invented progression',
    (tester) async {
      profiles.sourceCapabilities = ProfileCapabilities.backend;
      profiles.profile = profileFromJson(backend.backendProfile(), profileUser);
      await pumpScreen(tester);
      await tester.pumpAndSettle();
      expect(find.text('maria'), findsOneWidget);
      expect(find.text('340 XP'), findsOneWidget);
      expect(find.text('340 / 500 XP'), findsNothing);
      expect(find.text('Explorador/a'), findsNothing);
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Municipi'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom'),
        'Maria Casals',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom d’usuari'),
        'maria_c',
      );
      await tester.ensureVisible(find.text('Desar'));
      await tester.tap(find.text('Desar'));
      await tester.pumpAndSettle();
      expect(find.text('maria_c'), findsOneWidget);
      expect(find.text('Maria Casals'), findsOneWidget);
      await scrollTo(tester, find.text('Plans fets'));
      await tester.tap(find.text('Plans fets'));
      await tester.pumpAndSettle();
      await scrollTo(
        tester,
        find.text('Historial d’assistència disponible properament'),
      );
      expect(find.text('Encara no tens plans fets'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Server-only configuration shows unsupported notifications as pending with enlarged text',
    (tester) async {
      settings.supportedPreferences = {ProfilePreference.showMyPlans};
      settings.persistsPreferences = true;
      await pumpScreen(tester, configuration: true, scale: 2);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Recordatoris'));
      expect(
        find.byKey(const ValueKey('profile-preference-reminders')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('profile-preference-friendActivity')),
        findsNothing,
      );
      await scrollTo(tester, find.text('Eliminar compte'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Profile displays identity, statistics, levels and both activity tabs',
    (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();
      expect(find.text('Adam Ziani'), findsOneWidget);
      expect(find.text('adam'), findsOneWidget);
      expect(find.text('340 / 500 XP'), findsOneWidget);
      expect(find.text('4,7'), findsOneWidget);
      await tester.tap(find.byTooltip('Configuració'));
      expect(settingsOpened, 1);
      await tester.tap(find.text('Compartir perfil'));
      expect(shares, 1);
      final tile = find.byKey(const ValueKey('profile-activity-profile-event'));
      await scrollTo(tester, tile);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(
          tester
              .getSemantics(tile)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
      } finally {
        semantics.dispose();
      }
      await tester.tap(tile);
      expect(opened, 'profile-event');
      await tester.ensureVisible(find.text('Creats per mi'));
      await tester.tap(find.text('Creats per mi'));
      await tester.pumpAndSettle();
      expect(tester.widget<ProfileActivityTile>(tile).rating, isNull);
    },
  );

  testWidgets(
    'Profile distinguishes loading, errors, retry and empty attendance',
    (tester) async {
      final pending = Completer<UserProfile>();
      profiles.onGet = (_) => pending.future;
      await pumpScreen(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.completeError(StateError('Offline'));
      await tester.pumpAndSettle();
      expect(find.text('Tornar-ho a provar'), findsOneWidget);
      profiles.onGet = (_) async => sampleProfile(empty: true);
      profiles.onCreated = (_) async => [];
      await tester.tap(find.text('Tornar-ho a provar'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Encara no tens plans fets'));
      expect(find.text('Encara no tens plans fets'), findsOneWidget);
      await tester.ensureVisible(find.text('Creats per mi'));
      await tester.tap(find.text('Creats per mi'));
      await tester.pumpAndSettle();
      expect(find.text('Encara no has creat cap activitat'), findsOneWidget);
    },
  );

  testWidgets(
    'Edit profile keeps input after failure and closes after confirmed save',
    (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Biografia'),
        'Cinema i llibres',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Municipi'),
        'Vic',
      );
      profiles.onUpdate = (_, _, _) async => throw StateError('Offline');
      await tester.ensureVisible(find.text('Desar'));
      await tester.tap(find.text('Desar'));
      await tester.pumpAndSettle();
      expect(
        find.text('No hem pogut desar el perfil. Torna-ho a provar.'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Cinema i llibres'),
        findsOneWidget,
      );
      profiles.onUpdate = null;
      await tester.tap(find.text('Desar'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Cinema i llibres'), findsOneWidget);
      expect(find.text('Vic'), findsOneWidget);
    },
  );

  testWidgets('Cancel editing leaves the confirmed profile untouched', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Municipi'),
      'Vic',
    );
    await tester.tap(find.byTooltip('Tancar'));
    await tester.pumpAndSettle();
    expect(model.profile!.municipality, 'Girona');
    expect(profiles.updates, isEmpty);
  });

  testWidgets(
    'Settings toggles wait for confirmation and failed writes retain values',
    (tester) async {
      await pumpScreen(tester, configuration: true);
      await tester.pumpAndSettle();
      final control = find.byKey(
        const ValueKey('profile-preference-showMyPlans'),
      );
      final pending = Completer<ProfileSettings>();
      settings.onUpdate = (_, _, _) => pending.future;
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pump();
      await scrollTo(tester, control);
      expect(tester.widget<SwitchListTile>(control).value, isFalse);
      expect(tester.widget<SwitchListTile>(control).onChanged, isNull);
      pending.completeError(StateError('Offline'));
      await tester.pumpAndSettle();
      await scrollTo(tester, control);
      expect(tester.widget<SwitchListTile>(control).value, isFalse);
      settings.onUpdate = null;
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
      await scrollTo(tester, control);
      expect(tester.widget<SwitchListTile>(control).value, isTrue);
    },
  );

  testWidgets(
    'Unavailable services do not pretend Calendar is connected or enable deletion',
    (tester) async {
      await pumpScreen(tester, configuration: true);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Google Calendar'));
      expect(find.text('No connectat'), findsOneWidget);
      expect(find.text('Connectat'), findsNothing);
      await scrollTo(tester, find.text('Eliminar compte'));
      final tile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Eliminar compte'),
      );
      expect(tile.enabled, isFalse);
      expect(tile.onTap, isNull);
    },
  );

  testWidgets('Sign-out is available even when preferences fail to load', (
    tester,
  ) async {
    settings.onGet = (_) async => throw StateError('Offline');
    await pumpScreen(tester, configuration: true);
    await tester.pumpAndSettle();
    final leave = find.byKey(const ValueKey('profile-sign-out'));
    await scrollTo(tester, leave);
    await tester.tap(leave);
    await tester.pumpAndSettle();
    expect(signOuts, 1);
  });

  testWidgets(
    'Profile, editing and settings tolerate 320 px with doubled text',
    (tester) async {
      await pumpScreen(tester, scale: 2);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Plans fets'));
      expect(tester.takeException(), isNull);
      await scrollTo(tester, find.text('Editar perfil'));
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Tancar'));
      await tester.pumpAndSettle();
      await pumpScreen(tester, configuration: true, scale: 2);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Eliminar compte'));
      expect(tester.takeException(), isNull);
    },
  );
}
