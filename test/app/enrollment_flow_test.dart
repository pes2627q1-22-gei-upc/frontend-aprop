import 'dart:async';

import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:aprop/features/auth/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/activities/fake_enrollment_repository.dart';
import '../features/auth/fake_auth_repository.dart';
import 'app_navigation.dart';

void main() {
  late DemoAuthRepository auth;
  late FakeEnrollmentRepository enrollments;

  setUp(() async {
    auth = DemoAuthRepository();
    enrollments = FakeEnrollmentRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
  });

  tearDown(() => enrollments.dispose());

  Finder card(String id) => find.byKey(ValueKey(id));
  Finder cardLabel(String id, String label) =>
      find.descendant(of: card(id), matching: find.text(label));

  Future<void> pumpApp(
    WidgetTester tester, {
    bool useDemoEnrollment = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      APropApp(
        authRepository: auth,
        enrollmentRepository: useDemoEnrollment ? null : enrollments,
      ),
    );
    await tester.pumpAndSettle();
    await openMapTab(tester);
  }

  testWidgets(
    'List enrollment waits for confirmation; unenrolling can be undone',
    (tester) async {
      final confirmation = Completer<void>();
      enrollments.onEnroll = (_, _) => confirmation.future;
      await pumpApp(tester);
      await tester.tap(cardLabel('demo-jazz', 'M’hi apunto'));
      await tester.pump();
      expect(cardLabel('demo-jazz', 'Apuntant…'), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Activitat'), findsNothing);
      await tester.tap(cardLabel('demo-jazz', 'Apuntant…'));
      await tester.pump();
      expect(enrollments.enrolledRequests, ['demo-laiasoler/demo-jazz']);
      confirmation.complete();
      await tester.pumpAndSettle();
      expect(cardLabel('demo-jazz', 'Apuntat'), findsOneWidget);
      expect(cardLabel('demo-jazz', 'M’hi apunto'), findsNothing);

      // A la llista no es pregunta: el pla marxa, i «Desfer» el recupera sense
      // haver dit res al servidor.
      await tester.tap(cardLabel('demo-jazz', 'Desapunta’m'));
      await tester.pumpAndSettle();
      expect(find.text('Vols desapuntar-te?'), findsNothing);
      expect(find.text('T’has desapuntat de «Jazz al parc».'), findsOneWidget);
      expect(cardLabel('demo-jazz', 'M’hi apunto'), findsOneWidget);
      await tester.tap(find.text('Desfer'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Activitat'), findsNothing);
      expect(cardLabel('demo-jazz', 'Apuntat'), findsOneWidget);
      expect(enrollments.enrolledRequests, hasLength(1));
      expect(enrollments.unenrolledRequests, isEmpty);
      await tester.tap(find.text('Jazz al parc'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Activitat'), findsOneWidget);
      // A la fitxa, «Apuntat» al costat del títol i el botó per desapuntar-se.
      expect(find.text('Apuntat'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Desapunta’m'),
        findsOneWidget,
      );
      expect(find.text('Aquest pla ja és a la teva agenda.'), findsOneWidget);
    },
  );

  testWidgets('Without «Desfer», the list unenrolls after the delay', (
    tester,
  ) async {
    enrollments.emit('demo-laiasoler', {'demo-jazz'});
    await pumpApp(tester);
    expect(cardLabel('demo-jazz', 'Apuntat'), findsOneWidget);

    await tester.tap(cardLabel('demo-jazz', 'Desapunta’m'));
    await tester.pump();
    expect(cardLabel('demo-jazz', 'M’hi apunto'), findsOneWidget);
    expect(enrollments.unenrolledRequests, isEmpty);

    // «Desfer» goes away before the removal is sent.
    for (var i = 0; i < 49; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Desfer'), findsNothing);
    expect(enrollments.unenrolledRequests, isEmpty);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(enrollments.unenrolledRequests, ['demo-laiasoler/demo-jazz']);
    expect(cardLabel('demo-jazz', 'M’hi apunto'), findsOneWidget);
  });

  testWidgets('Detail enrollment is reflected in the list when returning', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Jazz al parc'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'M’hi apunto'));
    await tester.pumpAndSettle();
    expect(find.text('Apuntat'), findsOneWidget);
    await tester.tap(find.byTooltip('Tornar enrere'));
    await tester.pumpAndSettle();
    expect(cardLabel('demo-jazz', 'Apuntat'), findsOneWidget);
    expect(enrollments.enrolledRequests, ['demo-laiasoler/demo-jazz']);
  });

  testWidgets('Enrollment failure shows an error and can be retried', (
    tester,
  ) async {
    enrollments.onEnroll = (_, _) async => throw StateError('Offline');
    await pumpApp(tester);
    await tester.tap(cardLabel('demo-jazz', 'M’hi apunto'));
    await tester.pumpAndSettle();
    expect(cardLabel('demo-jazz', 'Apuntat'), findsNothing);
    expect(
      find.text('No t’hi hem pogut apuntar. Torna-ho a provar.'),
      findsOneWidget,
    );
    enrollments.onEnroll = null;
    await tester.tap(cardLabel('demo-jazz', 'M’hi apunto'));
    await tester.pumpAndSettle();
    expect(cardLabel('demo-jazz', 'Apuntat'), findsOneWidget);
    expect(
      find.text('No t’hi hem pogut apuntar. Torna-ho a provar.'),
      findsNothing,
    );
    expect(find.widgetWithText(AppBar, 'Activitat'), findsNothing);
  });

  testWidgets('Read failure offers recovery instead of an unsafe join action', (
    tester,
  ) async {
    enrollments.failReads = true;
    await pumpApp(tester);
    expect(cardLabel('demo-jazz', 'M’hi apunto'), findsNothing);
    expect(cardLabel('demo-jazz', 'Tornar-ho a provar'), findsOneWidget);
    expect(enrollments.enrolledRequests, isEmpty);
    enrollments.failReads = false;
    await tester.tap(cardLabel('demo-jazz', 'Tornar-ho a provar'));
    // Stream cancellation crosses async zones; flush it before fake-time frames.
    await tester.runAsync(() async {});
    await tester.pumpAndSettle();
    expect(cardLabel('demo-jazz', 'M’hi apunto'), findsOneWidget);
  });

  testWidgets('Demo plans survive sign-out and remain isolated by account', (
    tester,
  ) async {
    await pumpApp(tester, useDemoEnrollment: true);
    await tester.tap(cardLabel('demo-jazz', 'M’hi apunto'));
    await tester.pumpAndSettle();
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Inicia sessió'), findsOneWidget);

    await auth.register(
      firstName: 'Pol',
      lastName: 'Vidal',
      username: 'polvidal',
      email: 'pol@example.test',
      password: 'Password1!',
    );
    await auth.checkEmailVerified();
    await tester.pumpAndSettle();
    await openMapTab(tester);
    expect(cardLabel('demo-jazz', 'M’hi apunto'), findsOneWidget);
    expect(cardLabel('demo-jazz', 'Apuntat'), findsNothing);

    await auth.signOut();
    await tester.pumpAndSettle();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    await tester.pumpAndSettle();
    await openMapTab(tester);
    expect(cardLabel('demo-jazz', 'Apuntat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('Identificador de les inscripcions', () {
    AppUser user({String? serverId}) => AppUser(
      id: 'firebase-uid-pol',
      serverId: serverId,
      email: 'pol@example.test',
      firstName: 'Pol',
      lastName: 'Vidal',
      emailVerified: true,
      username: 'polvidal',
    );

    Future<void> pumpAs(WidgetTester tester, AppUser signedIn) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        APropApp(
          authRepository: FakeAuthRepository()..signedInUser = signedIn,
          enrollmentRepository: enrollments,
        ),
      );
      await tester.pumpAndSettle();
      await openMapTab(tester);
    }

    testWidgets(
      'Amb backend, fa servir l’UUID de l’usuari, no el de Firebase',
      (tester) async {
        const uuid = 'f53add44-367c-4c16-bbee-38878f3fed48';
        await pumpAs(tester, user(serverId: uuid));

        await tester.tap(cardLabel('demo-jazz', 'M’hi apunto'));
        await tester.pumpAndSettle();

        // L'Agenda llegeix les mateixes inscripcions: si fes servir un altre
        // identificador, no hi sortirien.
        expect(enrollments.enrolledRequests, ['$uuid/demo-jazz']);
        expect(cardLabel('demo-jazz', 'Apuntat'), findsOneWidget);
      },
    );

    testWidgets('Sense backend, fa servir l’identificador del compte', (
      tester,
    ) async {
      await pumpAs(tester, user());

      await tester.tap(cardLabel('demo-jazz', 'M’hi apunto'));
      await tester.pumpAndSettle();

      expect(enrollments.enrolledRequests, ['firebase-uid-pol/demo-jazz']);
    });
  });

  testWidgets(
    'A late response after sign-out does not update another account',
    (tester) async {
      final confirmation = Completer<void>();
      enrollments.onEnroll = (_, _) => confirmation.future;
      await pumpApp(tester);
      await tester.tap(cardLabel('demo-jazz', 'M’hi apunto'));
      await tester.pump();
      await auth.signOut();
      await tester.pumpAndSettle();
      await auth.register(
        firstName: 'Pol',
        lastName: 'Vidal',
        username: 'polvidal',
        email: 'pol@example.test',
        password: 'Password1!',
      );
      await auth.checkEmailVerified();
      await tester.pumpAndSettle();
      confirmation.complete();
      await tester.pumpAndSettle();
      await openMapTab(tester);
      expect(cardLabel('demo-jazz', 'Apuntat'), findsNothing);
      expect(cardLabel('demo-jazz', 'M’hi apunto'), findsOneWidget);
      expect(
        await tester.runAsync(
          () => enrollments.watchEnrolledActivityIds('demo-laiasoler').first,
        ),
        {'demo-jazz'},
      );
      expect(
        await tester.runAsync(
          () => enrollments.watchEnrolledActivityIds('demo-polvidal').first,
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
