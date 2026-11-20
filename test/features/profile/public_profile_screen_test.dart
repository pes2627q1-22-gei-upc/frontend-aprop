import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/profile/data/demo_public_profile_repository.dart';
import 'package:aprop/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'The friend button and «Compartir perfil» fit 320 px with doubled text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: PublicProfileScreen(
            userId: 'demo-person-marc',
            repository: DemoPublicProfileRepository(
              activityRepository: DemoActivityRepository(),
            ),
            onActivitySelected: (_) {},
            onSharePressed: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final friend = find.byKey(const ValueKey('public-profile-friend'));
      await tester.ensureVisible(friend);
      await tester.tap(friend);
      await tester.pumpAndSettle();

      expect(find.text('Sol·licitud enviada'), findsOneWidget);
      expect(find.text('Compartir perfil'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
