import 'dart:async';

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:aprop/features/profile/models/received_friend_request.dart';
import 'package:aprop/features/profile/presentation/screens/friends_list_screen.dart';
import 'package:aprop/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'friendship_test_support.dart';
import 'remove_friend_test_support.dart';

void main() {
  late ControlledFriendshipRepository friendships;
  late RemovalFriends friends;
  late RemovalProfiles profiles;
  late List<String> opened;
  setUp(() {
    friendships = ControlledFriendshipRepository(
      ReceivedFriendRequest(
        senderId: 'peer',
        receiverId: 'viewer',
        sentAt: DateTime.utc(2026),
      ),
    );
    friends = RemovalFriends();
    profiles = RemovalProfiles();
    opened = [];
    friendships.onFetch = () async => [];
    friendships.onRemove = () async {
      friends.items = [];
      profiles.friends = false;
    };
  });
  tearDown(() => friendships.dispose());

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool profile = false,
    String? owner,
    String viewer = 'viewer',
    String language = 'ca',
    bool largeText = false,
  }) async {
    tester.view.physicalSize = Size(largeText ? 320 : 390, 844);
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
              .copyWith(textScaler: TextScaler.linear(largeText ? 2 : 1)),
          child: child!,
        ),
        home: profile
            ? PublicProfileScreen(
                userId: 'peer',
                currentUserId: viewer,
                repository: profiles,
                friendshipRepository: friendships,
                onActivitySelected: (_) {},
              )
            : FriendsListScreen(
                repository: friends,
                friendshipRepository: friendships,
                currentUserId: viewer,
                userId: owner,
                onUserSelected: opened.add,
              ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder removeRow() => find.byKey(const ValueKey('remove-friend-peer'));
  Finder confirm() => find.byKey(const ValueKey('confirm-remove-friend'));
  Future<void> openProfileRemoval(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey('public-profile-friend-options')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar amistat'));
    await tester.pumpAndSettle();
  }

  for (final language in ['ca', 'es', 'en']) {
    for (final largeText in [false, true]) {
      testWidgets(
        'Own list confirms or cancels removal in $language at ${largeText ? '320 px/text ×2' : '390 px'} without opening a profile',
        (tester) async {
          final previous = LocaleController.active;
          final semantics = tester.ensureSemantics();
          try {
            LocaleController.active = Locale(language);
            final l10n = lookupAppLocalizations(Locale(language));
            await pumpScreen(tester, language: language, largeText: largeText);
            final action = find.byTooltip(
              l10n.friendRemoveFrom(removalPeer.displayName),
            );
            expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
            await tester.tap(action);
            await tester.pumpAndSettle();
            expect(find.text(l10n.friendRemoveTitle), findsOneWidget);
            expect(
              find.text(l10n.friendRemoveMessage(removalPeer.displayName)),
              findsOneWidget,
            );
            expect(tester.getSize(confirm()).height, greaterThanOrEqualTo(48));
            expect(
              tester.getSemantics(confirm()),
              matchesSemantics(
                label: l10n.friendRemove,
                isButton: true,
                hasEnabledState: true,
                isEnabled: true,
                hasTapAction: true,
                isFocusable: true,
                hasFocusAction: true,
              ),
            );
            await tester.tap(find.text(l10n.shareCancel));
            await tester.pumpAndSettle();
            expect(friendships.removals, isEmpty);
            expect(find.byKey(const ValueKey('friend-peer')), findsOneWidget);
            await tester.tap(action);
            await tester.pumpAndSettle();
            await tester.tap(confirm());
            await tester.pumpAndSettle();
            expect(friendships.removals, [('viewer', 'peer')]);
            expect(find.byKey(const ValueKey('friend-peer')), findsNothing);
            expect(
              find.text(l10n.friendRemoveSuccess(removalPeer.displayName)),
              findsOneWidget,
            );
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
    'List shows progress without optimistic removal, then error and retry',
    (tester) async {
      final pending = Completer<void>();
      friendships.onRemove = () => pending.future;
      await pumpScreen(tester);
      await tester.tap(removeRow());
      await tester.pumpAndSettle();
      await tester.tap(confirm());
      await tester.pump();
      expect(find.byKey(const ValueKey('friend-peer')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(friendships.removals, hasLength(1));
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(
        find.text('No hem pogut eliminar l’amistat. Torna-ho a provar.'),
        findsOneWidget,
      );
      friendships.onRemove = () async {
        friends.items = [];
      };
      await tester.tap(removeRow());
      await tester.pumpAndSettle();
      await tester.tap(confirm());
      await tester.pumpAndSettle();
      expect(friendships.removals, hasLength(2));
      expect(find.byKey(const ValueKey('friend-peer')), findsNothing);
    },
  );

  testWidgets(
    'Another person’s list has profile navigation but no removal action',
    (tester) async {
      await pumpScreen(tester, owner: 'other-person');
      expect(removeRow(), findsNothing);
      await tester.tap(find.byKey(const ValueKey('friend-peer')));
      expect(opened, ['peer']);
      expect(friendships.removals, isEmpty);
    },
  );

  testWidgets(
    'Profile menu uses the same confirmation and preserves the friendship on cancel or failure',
    (tester) async {
      await pumpScreen(tester, profile: true);
      await openProfileRemoval(tester);
      await tester.tap(find.text('Cancel·lar'));
      await tester.pumpAndSettle();
      expect(friendships.removals, isEmpty);
      expect(find.text('Amiga/Amic'), findsOneWidget);
      friendships.onRemove = () async => throw StateError('offline');
      await openProfileRemoval(tester);
      await tester.tap(confirm());
      await tester.pumpAndSettle();
      expect(
        find.text('No hem pogut eliminar l’amistat. Torna-ho a provar.'),
        findsOneWidget,
      );
      expect(find.text('Amiga/Amic'), findsOneWidget);
      friendships.onRemove = () async {
        profiles.friends = false;
      };
      await openProfileRemoval(tester);
      await tester.tap(confirm());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('public-profile-friend-options')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('public-profile-friend-options')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Eliminar amistat'), findsNothing);
      expect(find.text('Bloquejar'), findsOneWidget);
      await tester.tapAt(const Offset(10, 400));
      await tester.pumpAndSettle();
      expect(find.text('Afegeix com a amic'), findsOneWidget);
      expect(find.text('Amiga/Amic'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'An old confirmation cannot remove a friend after changing account',
    (tester) async {
      await pumpScreen(tester);
      await tester.tap(removeRow());
      await tester.pumpAndSettle();
      await pumpScreen(tester, viewer: 'another-account');
      await tester.tap(confirm());
      await tester.pumpAndSettle();
      expect(friendships.removals, isEmpty);
      expect(find.byKey(const ValueKey('friend-peer')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
