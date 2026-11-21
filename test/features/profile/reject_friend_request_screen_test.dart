import 'dart:async';

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/profile/data/demo_friendship_repository.dart';
import 'package:aprop/features/profile/data/demo_public_profile_repository.dart';
import 'package:aprop/features/profile/models/received_friend_request.dart';
import 'package:aprop/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'friendship_test_support.dart';

void main() {
  for (final language in ['ca', 'es', 'en']) {
    testWidgets(
      'Profile decline loading/retry/feedback fits 320 px with doubled text in $language',
      (tester) async {
        final locale = Locale(language);
        final l10n = lookupAppLocalizations(locale);
        final oldLocale = LocaleController.active;
        LocaleController.active = locale;
        addTearDown(() => LocaleController.active = oldLocale);
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final request = DemoFriendshipRepository.marcRequest('viewer');
        final friendships = ControlledFriendshipRepository(request);
        final pending = Completer<FriendRequestResolution>();
        friendships.onRespond = (_) => pending.future;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: PublicProfileScreen(
              userId: request.senderId,
              currentUserId: 'viewer',
              repository: DemoPublicProfileRepository(
                activityRepository: DemoActivityRepository(),
              ),
              friendshipRepository: friendships,
              onActivitySelected: (_) {},
              onSharePressed: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final accept = find.byKey(const ValueKey('public-profile-friend'));
        final decline = find.byKey(
          const ValueKey('public-profile-reject-friend'),
        );
        expect(find.text(l10n.notifAccept), findsOneWidget);
        expect(find.text(l10n.notifDecline), findsOneWidget);
        await tester.ensureVisible(decline);
        await tester.tap(decline);
        await tester.pump();
        expect(find.text(l10n.friendRejecting), findsOneWidget);
        expect(tester.widget<ButtonStyleButton>(accept).onPressed, isNull);
        expect(tester.widget<ButtonStyleButton>(decline).onPressed, isNull);
        pending.completeError(StateError('offline'));
        await tester.pumpAndSettle();
        expect(find.text(l10n.friendRejectError), findsOneWidget);
        expect(find.text(l10n.notifRequestDeclined), findsNothing);
        expect(tester.widget<ButtonStyleButton>(decline).onPressed, isNotNull);
        friendships.onRespond = null;
        await tester.ensureVisible(decline);
        await tester.tap(decline);
        await tester.pumpAndSettle();
        expect(find.text(l10n.notifRequestDeclined), findsOneWidget);
        expect(decline, findsNothing);
        expect(find.text(l10n.friendAdd), findsOneWidget);
        expect(find.text(l10n.friendRejectError), findsNothing);
        expect(find.text(l10n.friendAlready), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await friendships.dispose();
      },
    );
  }
}
