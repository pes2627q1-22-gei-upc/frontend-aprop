import 'dart:async';

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/notifications/presentation/formatters/notification_formatter.dart';
import 'package:aprop/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notification_repository.dart';
import 'notification_test_data.dart';

void main() {
  late FakeNotificationRepository repository;
  late List<String> people;
  setUp(() {
    repository = FakeNotificationRepository(
      inboxes: {
        'user-a': [acceptedFriendNotice()],
        'user-b': [acceptedFriendNotice(id: 'other-account')],
      },
    );
    people = [];
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    String userId = 'user-a',
    bool profileAvailable = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NotificationsScreen(
            userId: userId,
            repository: repository,
            onActivitySelected: (_) => fail('This notice has no activity'),
            onPersonSelected: profileAvailable ? people.add : null,
            now: () => notificationNow,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder profile() =>
      find.byKey(const ValueKey('notification-friend-profile-accepted'));
  Finder unread() => find.byKey(const ValueKey('notification-unread-accepted'));

  testWidgets(
    'Profile opens only after confirmed reading, with no duplicate write or response',
    (tester) async {
      final pending = Completer<void>();
      repository.onRead = () => pending.future;
      await pumpScreen(tester);
      await tester.tap(profile());
      await tester.pump();
      expect(people, isEmpty);
      expect(repository.reads, ['user-a/accepted']);
      expect(unread(), findsOneWidget);
      expect(tester.widget<TextButton>(profile()).onPressed, isNull);
      await tester.tap(profile());
      expect(repository.reads, hasLength(1));
      pending.complete();
      await tester.pumpAndSettle();
      expect(people, [notificationPerson.id]);
      expect(unread(), findsNothing);
      expect(repository.responses, isEmpty);
      expect(find.text('Acceptar'), findsNothing);
      expect(find.text('Rebutjar'), findsNothing);
    },
  );

  testWidgets('An already-read acceptance opens without a read write', (
    tester,
  ) async {
    repository.inboxes['user-a'] = [acceptedFriendNotice(isRead: true)];
    await pumpScreen(tester);
    await tester.tap(profile());
    await tester.pumpAndSettle();
    expect(people, [notificationPerson.id]);
    expect(repository.reads, isEmpty);
    expect(repository.responses, isEmpty);
  });

  testWidgets(
    'Read failure preserves unread state and permits a successful retry',
    (tester) async {
      repository.onRead = () async => throw StateError('offline');
      await pumpScreen(tester);
      await tester.tap(profile());
      await tester.pumpAndSettle();
      expect(people, isEmpty);
      expect(unread(), findsOneWidget);
      expect(
        find.text(
          'No hem pogut marcar l’avís com a llegit. Torna-ho a provar.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<TextButton>(profile()).onPressed, isNotNull);
      repository.onRead = null;
      await tester.tap(profile());
      await tester.pumpAndSettle();
      expect(people, [notificationPerson.id]);
      expect(repository.reads, ['user-a/accepted', 'user-a/accepted']);
      expect(unread(), findsNothing);
      expect(repository.responses, isEmpty);
    },
  );

  testWidgets(
    'Without a profile destination the card remains readable and has no dead action',
    (tester) async {
      await pumpScreen(tester, profileAvailable: false);
      expect(profile(), findsNothing);
      expect(find.text('Perfil disponible properament'), findsOneWidget);
      await tester.tap(find.text(notificationMessage(acceptedFriendNotice())));
      await tester.pumpAndSettle();
      expect(unread(), findsNothing);
      expect(repository.reads, ['user-a/accepted']);
      expect(people, isEmpty);
      expect(repository.responses, isEmpty);
    },
  );

  testWidgets(
    'A late read after switching accounts cannot open the old profile',
    (tester) async {
      final pending = Completer<void>();
      repository.onRead = () => pending.future;
      await pumpScreen(tester);
      await tester.tap(profile());
      await tester.pump();
      await pumpScreen(tester, userId: 'user-b');
      pending.complete();
      await tester.pumpAndSettle();
      expect(people, isEmpty);
      expect(
        find.byKey(const ValueKey('notification-other-account')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-unread-other-account')),
        findsOneWidget,
      );
      expect(repository.reads, ['user-a/accepted']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A disposed inbox ignores the completion of its read', (
    tester,
  ) async {
    final pending = Completer<void>();
    repository.onRead = () => pending.future;
    await pumpScreen(tester);
    await tester.tap(profile());
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pumpAndSettle();
    expect(people, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
