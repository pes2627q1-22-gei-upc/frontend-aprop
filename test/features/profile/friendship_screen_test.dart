import 'dart:async';

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/profile/data/demo_friendship_repository.dart';
import 'package:aprop/features/profile/data/demo_public_profile_repository.dart';
import 'package:aprop/features/profile/models/received_friend_request.dart';
import 'package:aprop/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'friendship_test_support.dart';

void main() {
  testWidgets(
    'Incoming profile request shows Acceptar, loading, retry and the friend badge at 320 px with doubled text',
    (tester) async {
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
              friendshipRepository: friendships,
              currentUserId: () => 'viewer',
            ),
            friendshipRepository: friendships,
            onActivitySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('public-profile-friend'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(find.text('Acceptant…'), findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Acceptar'), findsOneWidget);
      expect(find.textContaining('No hem pogut acceptar'), findsOneWidget);
      friendships.onRespond = null;
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Amiga/Amic'), findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
      expect(find.textContaining('No hem pogut acceptar'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await friendships.dispose();
    },
  );
}
