import 'dart:async';

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/presentation/view_models/enrollment_view_model.dart';
import 'package:aprop/features/activities/presentation/widgets/enrollment_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_enrollment_repository.dart';

void main() {
  for (final primary in [false, true]) {
    testWidgets(
      'Both button variants remain usable with enlarged text: $primary',
      (tester) async {
        final repository = FakeEnrollmentRepository();
        final viewModel = EnrollmentViewModel(
          userId: 'user-a',
          repository: repository,
        );
        viewModel.load();
        addTearDown(() async {
          viewModel.dispose();
          await repository.dispose();
        });
        tester.view.physicalSize = const Size(320, 640);
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
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: EnrollmentAction(
                  viewModel: viewModel,
                  activityId: 'demo-jazz',
                  activityTitle: 'Jazz al parc',
                  primary: primary,
                  showHelper: primary,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final confirmation = Completer<void>();
        repository.onEnroll = (_, _) => confirmation.future;
        await tester.tap(find.text('M’hi apunto'));
        await tester.pump();
        expect(find.text('Apuntant…'), findsOneWidget);
        expect(tester.takeException(), isNull);
        confirmation.complete();
        await tester.pumpAndSettle();
        expect(find.text('Apuntat'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('A failed unenrollment keeps «Apuntat» and shows the error', (
    tester,
  ) async {
    final repository = FakeEnrollmentRepository()
      ..emit('user-a', {'demo-jazz'})
      ..onUnenroll = (_, _) async => throw StateError('Offline');
    final viewModel = EnrollmentViewModel(
      userId: 'user-a',
      repository: repository,
    );
    viewModel.load();
    addTearDown(() async {
      viewModel.dispose();
      await repository.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EnrollmentAction(
            viewModel: viewModel,
            activityId: 'demo-jazz',
            activityTitle: 'Jazz al parc',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apuntat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Treurem «Jazz al parc»'), findsOneWidget);
    await tester.tap(find.text('Desapunta’m'));
    await tester.pumpAndSettle();

    expect(find.text('Apuntat'), findsOneWidget);
    expect(
      find.text('No t’hem pogut desapuntar. Torna-ho a provar.'),
      findsOneWidget,
    );
    expect(repository.unenrolledRequests, ['user-a/demo-jazz']);
  });

  testWidgets('No visible tooltip; the screen reader still gets the hint', (
    tester,
  ) async {
    final repository = FakeEnrollmentRepository()
      ..emit('user-a', {'demo-jazz'});
    final viewModel = EnrollmentViewModel(
      userId: 'user-a',
      repository: repository,
    );
    viewModel.load();
    addTearDown(() async {
      viewModel.dispose();
      await repository.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EnrollmentAction(
            viewModel: viewModel,
            activityId: 'demo-jazz',
            activityTitle: 'Jazz al parc',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Tooltip), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.tooltip == 'Desapuntar-me de Jazz al parc',
      ),
      findsOneWidget,
    );
  });
}
