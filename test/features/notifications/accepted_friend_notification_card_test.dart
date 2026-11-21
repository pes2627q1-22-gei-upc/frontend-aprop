import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/core/l10n/locale_controller.dart';
import 'package:aprop/features/notifications/presentation/widgets/notification_card.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notification_test_data.dart';

void main() {
  for (final language in ['ca', 'es', 'en']) {
    for (final largeText in [false, true]) {
      testWidgets(
        'Accepted friendship identifies the actor and opens their profile in $language at ${largeText ? '320 px/text ×2' : '390 px'}',
        (tester) async {
          final semantics = tester.ensureSemantics();
          final previousLocale = LocaleController.active;
          try {
            LocaleController.active = Locale(language);
            final l10n = lookupAppLocalizations(Locale(language));
            var opened = 0;
            final responses = <bool>[];
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
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(largeText ? 2 : 1)),
                  child: child!,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: NotificationCard(
                      notification: acceptedFriendNotice(),
                      profileAvailable: true,
                      onOpen: () => opened++,
                      onRespond: responses.add,
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              find.text(
                l10n.notifMessageFriendAccepted(notificationPerson.name),
              ),
              findsOneWidget,
            );
            expect(find.text(l10n.notifCategorySocial), findsOneWidget);
            expect(find.text(l10n.timeOfDay('18', '00')), findsOneWidget);
            expect(find.text('MV'), findsOneWidget);
            expect(
              find.byKey(const ValueKey('notification-unread-accepted')),
              findsOneWidget,
            );
            expect(find.text(l10n.notifAccept), findsNothing);
            expect(find.text(l10n.notifDecline), findsNothing);
            final button = find.byKey(
              const ValueKey('notification-friend-profile-accepted'),
            );
            expect(find.text(l10n.actViewProfile), findsOneWidget);
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
            expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
            expect(
              tester.getSemantics(
                find.bySemanticsLabel(
                  l10n.notifViewFriendProfile(notificationPerson.name),
                ),
              ),
              matchesSemantics(
                label: l10n.notifViewFriendProfile(notificationPerson.name),
                isButton: true,
                hasEnabledState: true,
                isEnabled: true,
                hasTapAction: true,
                isFocusable: true,
                hasFocusAction: true,
              ),
            );
            await tester.ensureVisible(button);
            await tester.tap(button);
            expect(opened, 1);
            expect(responses, isEmpty);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
            LocaleController.active = previousLocale;
          }
        },
      );
    }
  }
}
