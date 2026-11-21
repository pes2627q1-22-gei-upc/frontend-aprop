import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/notifications/models/app_notification.dart';
import 'package:aprop/features/notifications/presentation/widgets/friend_request_notification_actions.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpActions(
    WidgetTester tester, {
    String language = 'ca',
    double scale = 1,
    double width = 390,
    FriendRequestStatus status = FriendRequestStatus.pending,
    bool responding = false,
    bool enabled = true,
    ValueChanged<bool>? onRespond,
  }) async {
    tester.view.physicalSize = Size(width, 844);
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
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: FriendRequestNotificationActions(
                notificationId: 'notice',
                senderName: 'Àlex Martí i Solé',
                status: status,
                responding: responding,
                enabled: enabled,
                onRespond: onRespond ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder accept() => find.byKey(const ValueKey('notification-accept-notice'));
  Finder decline() => find.byKey(const ValueKey('notification-decline-notice'));

  for (final language in ['ca', 'es', 'en']) {
    for (final largeText in [false, true]) {
      testWidgets(
        'Actions identify the sender and fit ${largeText ? '320 px/text ×2' : '390 px'} in $language',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            final responses = <bool>[];
            await pumpActions(
              tester,
              language: language,
              scale: largeText ? 2 : 1,
              width: largeText ? 320 : 390,
              onRespond: responses.add,
            );
            final l10n = lookupAppLocalizations(Locale(language));
            expect(find.text(l10n.notifAccept), findsOneWidget);
            expect(find.text(l10n.notifDecline), findsOneWidget);
            for (final button in [accept(), decline()]) {
              expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
              expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
            }
            expect(
              tester.getSemantics(
                find.bySemanticsLabel(
                  l10n.notifAcceptRequestFrom('Àlex Martí i Solé'),
                ),
              ),
              matchesSemantics(
                label: l10n.notifAcceptRequestFrom('Àlex Martí i Solé'),
                isButton: true,
                hasEnabledState: true,
                isEnabled: true,
                hasTapAction: true,
                isFocusable: true,
                hasFocusAction: true,
              ),
            );
            expect(
              tester.getSemantics(
                find.bySemanticsLabel(
                  l10n.notifDeclineRequestFrom('Àlex Martí i Solé'),
                ),
              ),
              matchesSemantics(
                label: l10n.notifDeclineRequestFrom('Àlex Martí i Solé'),
                isButton: true,
                hasEnabledState: true,
                isEnabled: true,
                hasTapAction: true,
                isFocusable: true,
                hasFocusAction: true,
              ),
            );
            if (largeText) {
              expect(
                tester.getTopLeft(decline()).dy,
                greaterThan(tester.getBottomLeft(accept()).dy),
              );
            } else {
              expect(
                tester.getTopLeft(decline()).dy,
                tester.getTopLeft(accept()).dy,
              );
            }
            await tester.ensureVisible(accept());
            await tester.tap(accept());
            await tester.ensureVisible(decline());
            await tester.tap(decline());
            expect(responses, [true, false]);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
  testWidgets(
    'Submitting shows progress text, disables both buttons and does not show a premature result',
    (tester) async {
      final responses = <bool>[];
      await pumpActions(tester, responding: true, onRespond: responses.add);
      expect(find.text('Enviant la resposta'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(accept()).onPressed, isNull);
      expect(tester.widget<ButtonStyleButton>(decline()).onPressed, isNull);
      expect(find.text('Sol·licitud acceptada'), findsNothing);
      expect(find.text('Sol·licitud rebutjada'), findsNothing);
      expect(responses, isEmpty);
    },
  );
  testWidgets(
    'Disabling while reading or refreshing does not pretend a response is being sent',
    (tester) async {
      await pumpActions(tester, enabled: false);
      expect(tester.widget<ButtonStyleButton>(accept()).onPressed, isNull);
      expect(tester.widget<ButtonStyleButton>(decline()).onPressed, isNull);
      expect(find.text('Enviant la resposta'), findsNothing);
    },
  );
  for (final status in [
    FriendRequestStatus.accepted,
    FriendRequestStatus.rejected,
  ]) {
    testWidgets(
      'Confirmed $status renders text and icon without pending actions',
      (tester) async {
        await pumpActions(tester, status: status, responding: true);
        expect(
          find.text(
            status == FriendRequestStatus.accepted
                ? 'Sol·licitud acceptada'
                : 'Sol·licitud rebutjada',
          ),
          findsOneWidget,
        );
        expect(
          find.byIcon(
            status == FriendRequestStatus.accepted
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
          ),
          findsOneWidget,
        );
        expect(accept(), findsNothing);
        expect(decline(), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Native focus semantics and Tab/Enter/Space activation are preserved',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final responses = <bool>[];
        await pumpActions(tester, onRespond: responses.add);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          tester.getSemantics(
            find.bySemanticsLabel(
              'Acceptar la sol·licitud d’amistat de Àlex Martí i Solé',
            ),
          ),
          matchesSemantics(
            label: 'Acceptar la sol·licitud d’amistat de Àlex Martí i Solé',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            isFocusable: true,
            isFocused: true,
            hasFocusAction: true,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(responses, [true]);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          tester.getSemantics(
            find.bySemanticsLabel(
              'Rebutjar la sol·licitud d’amistat de Àlex Martí i Solé',
            ),
          ),
          matchesSemantics(
            label: 'Rebutjar la sol·licitud d’amistat de Àlex Martí i Solé',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
            isFocusable: true,
            isFocused: true,
            hasFocusAction: true,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(responses, [true, false]);
      } finally {
        semantics.dispose();
      }
    },
  );
}
