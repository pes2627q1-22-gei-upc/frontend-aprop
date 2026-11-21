import 'dart:async';

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:aprop/features/profile/data/demo_friendship_repository.dart';
import 'package:aprop/features/profile/models/blocked_user.dart';
import 'package:aprop/features/profile/presentation/screens/blocked_users_screen.dart';
import 'package:aprop/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'friendship_test_support.dart';
import 'remove_friend_test_support.dart';

void main() {
  late ControlledFriendshipRepository repo;
  late RemovalProfiles profiles;
  late List<String> opened;
  setUp(() {
    repo = ControlledFriendshipRepository(
      DemoFriendshipRepository.marcRequest('viewer'),
    );
    repo.onFetch = () async => [];
    profiles = RemovalProfiles();
    opened = [];
  });
  tearDown(() => repo.dispose());
  Future<void> pump(
    WidgetTester tester, {
    String language = 'ca',
    bool large = false,
    bool profile = false,
    String viewer = 'viewer',
  }) async {
    tester.view.physicalSize = Size(large ? 320 : 390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
          child: child!,
        ),
        home: profile
            ? PublicProfileScreen(
                userId: 'peer',
                currentUserId: viewer,
                repository: profiles,
                friendshipRepository: repo,
                onActivitySelected: (_) {},
              )
            : BlockedUsersScreen(
                userId: viewer,
                repository: repo,
                onUserSelected: opened.add,
              ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder confirm() => find.byKey(const ValueKey('confirm-user-block'));
  Future<void> openBlock(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey('public-profile-friend-options')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquejar'));
    await tester.pumpAndSettle();
  }

  for (final language in ['ca', 'es', 'en']) {
    for (final large in [false, true]) {
      testWidgets(
        'Blocked list confirms/cancels unblock accessibly in $language at ${large ? '320/text×2' : '390'}',
        (tester) async {
          final previous = LocaleController.active;
          final semantics = tester.ensureSemantics();
          try {
            LocaleController.active = Locale(language);
            final l10n = lookupAppLocalizations(Locale(language));
            repo.blockedUsers['peer'] = BlockedUser(
              user: removalPeer,
              blockedAt: DateTime.utc(2026),
            );
            await pump(tester, language: language, large: large);
            final action = find.byKey(const ValueKey('unblock-user-peer'));
            expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
            expect(
              tester.getSemantics(
                find.bySemanticsLabel(l10n.userUnblockFrom('Marc Vidal')),
              ),
              matchesSemantics(
                label: l10n.userUnblockFrom('Marc Vidal'),
                isButton: true,
                hasEnabledState: true,
                isEnabled: true,
                hasTapAction: true,
                isFocusable: true,
                hasFocusAction: true,
              ),
            );
            await tester.tap(action);
            await tester.pumpAndSettle();
            expect(
              find.text(l10n.userUnblockTitle('Marc Vidal')),
              findsOneWidget,
            );
            expect(find.text(l10n.userUnblockMessage), findsOneWidget);
            await tester.tap(find.text(l10n.shareCancel));
            await tester.pumpAndSettle();
            expect(repo.unblocks, isEmpty);
            await tester.tap(action);
            await tester.pumpAndSettle();
            await tester.tap(confirm());
            await tester.pumpAndSettle();
            expect(repo.unblocks, ['peer']);
            expect(
              find.byKey(const ValueKey('blocked-user-peer')),
              findsNothing,
            );
            expect(find.text(l10n.blockedEmptyTitle), findsOneWidget);
            expect(opened, isEmpty);
            expect(tester.takeException(), isNull);
          } finally {
            LocaleController.active = previous;
            semantics.dispose();
          }
        },
      );
    }
  }
  testWidgets(
    'Blocked list shows error/retry and keeps a row during failed unblock',
    (tester) async {
      repo.onFetchBlocked = () async => throw StateError('offline');
      await pump(tester);
      expect(
        find.text(
          'No hem pogut carregar els usuaris bloquejats. Torna-ho a provar.',
        ),
        findsOneWidget,
      );
      repo.blockedUsers['peer'] = BlockedUser(
        user: removalPeer,
        blockedAt: DateTime.utc(2026),
      );
      repo.onFetchBlocked = null;
      await tester.tap(
        find.text(lookupAppLocalizations(const Locale('ca')).retry),
      );
      await tester.pumpAndSettle();
      final pending = Completer<void>();
      repo.onUnblock = (_) => pending.future;
      await tester.tap(find.byKey(const ValueKey('unblock-user-peer')));
      await tester.pumpAndSettle();
      await tester.tap(confirm());
      await tester.pump();
      expect(find.byKey(const ValueKey('blocked-user-peer')), findsOneWidget);
      expect(find.text('Desbloquejant l’usuari'), findsOneWidget);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(
        find.text('No hem pogut desbloquejar l’usuari. Torna-ho a provar.'),
        findsOneWidget,
      );
      repo.onUnblock = null;
      await tester.tap(find.byKey(const ValueKey('unblock-user-peer')));
      await tester.pumpAndSettle();
      await tester.tap(confirm());
      await tester.pumpAndSettle();
      expect(find.text('No tens usuaris bloquejats'), findsOneWidget);
    },
  );
  testWidgets(
    'Public profile block cancels, fails and retries without losing the friendship prematurely',
    (tester) async {
      await pump(tester, profile: true, large: true);
      await openBlock(tester);
      await tester.tap(find.text('Cancel·lar'));
      await tester.pumpAndSettle();
      expect(repo.blocks, isEmpty);
      expect(find.text('Amiga/Amic'), findsOneWidget);
      repo.onBlock = (_) async => throw StateError('offline');
      await openBlock(tester);
      await tester.tap(confirm());
      await tester.pumpAndSettle();
      expect(find.text('Amiga/Amic'), findsOneWidget);
      expect(
        find.text('No hem pogut bloquejar l’usuari. Torna-ho a provar.'),
        findsOneWidget,
      );
      repo.onBlock = (target) async {
        profiles.friends = false;
        return BlockedUser(user: target, blockedAt: DateTime.utc(2026));
      };
      await openBlock(tester);
      await tester.tap(confirm());
      await tester.pumpAndSettle();
      expect(find.text('Has bloquejat aquest usuari.'), findsOneWidget);
      expect(find.text('Amiga/Amic'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('public-profile-friend-options')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Desbloquejar'), findsOneWidget);
      expect(find.text('Eliminar amistat'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Account changes invalidate an already-open block confirmation', (
    tester,
  ) async {
    await pump(tester, profile: true);
    await openBlock(tester);
    await pump(tester, profile: true, viewer: 'another-account');
    await tester.tap(confirm());
    await tester.pumpAndSettle();
    expect(repo.blocks, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
