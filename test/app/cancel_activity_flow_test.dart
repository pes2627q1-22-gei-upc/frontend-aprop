import 'package:aprop/app/aprop_app.dart';
import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/models/new_activity.dart';
import 'package:aprop/features/auth/data/demo_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/activities/fake_enrollment_repository.dart';
import 'app_navigation.dart';

/// #46: who created an activity can cancel it before it starts.
void main() {
  late DemoActivityRepository catalogue;
  late FakeEnrollmentRepository enrollments;
  late String ownId;

  setUp(() async {
    catalogue = DemoActivityRepository();
    enrollments = FakeEnrollmentRepository();
    // An activity of Laia's (the signed-in demo account) next week.
    final created = await catalogue.createActivity(
      NewActivity(
        title: 'Concert al claustre',
        description: 'Música de cambra.',
        categories: ['agenda:categories/musica'],
        startsAt: DateTime.now().add(const Duration(days: 7)),
        imageAsset: 'assets/images/jazz_al_parc.jpg',
        // Lleida: far from the demo activities, so its marker is not grouped.
        location: const GeoPoint(latitude: 41.6176, longitude: 0.62),
        creator: const ActivityCreator(
          name: 'Laia Soler',
          userId: 'demo-laiasoler',
          isFriend: false,
        ),
      ),
    );
    ownId = created.id;
  });
  tearDown(() => enrollments.dispose());

  Future<void> openActivity(
    WidgetTester tester,
    String id,
    String title,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = DemoAuthRepository();
    await auth.signIn(usernameOrEmail: 'laiasoler', password: 'Aprop2026!');
    await tester.pumpWidget(
      APropApp(
        authRepository: auth,
        activityRepository: catalogue,
        enrollmentRepository: enrollments,
      ),
    );
    await tester.pumpAndSettle();
    await openMapTab(tester);
    await tapMarker(tester, id);
    await tester.tap(
      find.descendant(of: find.byKey(ValueKey(id)), matching: find.text(title)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) =>
      tester.scrollUntilVisible(
        target,
        300,
        scrollable: find.byType(Scrollable).last,
      );

  testWidgets('La creadora la cancel·la amb confirmació i surt «Cancel·lada»', (
    tester,
  ) async {
    await openActivity(tester, ownId, 'Concert al claustre');
    expect(find.byTooltip('Edita l’activitat'), findsOneWidget);

    final cancel = find.byKey(const ValueKey('activity-cancel'));
    await scrollTo(tester, cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(find.text('Vols cancel·lar l’activitat?'), findsOneWidget);

    // «Tornar» does nothing.
    await tester.tap(find.text('Tornar'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('activity-cancelled-badge')),
      findsNothing,
    );

    await tester.tap(cancel);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('activity-cancel-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Has cancel·lat l’activitat. Hem avisat les persones apuntades.',
      ),
      findsOneWidget,
    );
    // No more joining, editing or cancelling.
    expect(
      find.byKey(const ValueKey('activity-cancelled-badge')),
      findsWidgets,
    );
    expect(find.text('M’hi apunto'), findsNothing);
    expect(find.byKey(const ValueKey('activity-cancel')), findsNothing);
    expect(find.byTooltip('Edita l’activitat'), findsNothing);

    // The map card shows it too.
    await tester.tap(find.byTooltip('Tornar enrere'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(ValueKey(ownId)),
        matching: find.byKey(const ValueKey('activity-cancelled-badge')),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Qui no l’ha creada no la pot cancel·lar', (tester) async {
    // Laia is not the creator of the official «Jazz al parc».
    await openActivity(tester, 'demo-jazz', 'Jazz al parc');

    expect(find.byKey(const ValueKey('activity-cancel')), findsNothing);
  });
}
