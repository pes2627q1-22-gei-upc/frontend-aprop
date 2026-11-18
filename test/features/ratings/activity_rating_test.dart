import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/ratings/data/demo_rating_repository.dart';
import 'package:aprop/features/ratings/presentation/view_models/rating_view_model.dart';
import 'package:aprop/features/ratings/presentation/widgets/activity_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RatingViewModel viewModel;

  setUp(() {
    viewModel = RatingViewModel(
      userId: 'u',
      repository: DemoRatingRepository(),
    );
    addTearDown(viewModel.dispose);
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ActivityRating(viewModel: viewModel, activityId: 'a1'),
      ),
    ),
  );

  testWidgets('tapping a star submits it and the title changes', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Com t’ha anat?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('star-4')));
    await tester.pumpAndSettle();

    expect(viewModel.scoreFor('a1'), 4);
    expect(find.text('Ja has valorat aquesta activitat'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
  });

  testWidgets('organizer is highlighted when given, generic copy otherwise', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityRating(
            viewModel: viewModel,
            activityId: 'a1',
            organizer: const ActivityCreator(
              name: 'Laia Soler',
              isFriend: true,
            ),
          ),
        ),
      ),
    );
    expect(
      find.text('Com ha anat l’organitzador/a Laia Soler?'),
      findsOneWidget,
    );
    expect(find.text('Com t’ha anat?'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('star-5')));
    await tester.pumpAndSettle();
    expect(find.text('Ja has valorat Laia Soler'), findsOneWidget);

    await pump(tester); // no organizer (official activity)
    expect(find.textContaining('organitzador'), findsNothing);
  });

  testWidgets('already rated without a known score shows only the text', (
    tester,
  ) async {
    final repository = DemoRatingRepository();
    await repository.rate(userId: 'u', activityId: 'a1', score: 2);
    viewModel = RatingViewModel(userId: 'u', repository: repository);
    addTearDown(viewModel.dispose);
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('star-3')));
    await tester.pumpAndSettle();

    expect(find.text('Ja has valorat aquesta activitat'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNothing);
    expect(find.byKey(const ValueKey('star-1')), findsNothing);
  });

  Future<void> rateFirst(WidgetTester tester, int score) async {
    await pump(tester);
    await tester.tap(find.byKey(ValueKey('star-$score')));
    await tester.pumpAndSettle();
  }

  testWidgets('edit prefills the score and saves the new one', (tester) async {
    await rateFirst(tester, 2);
    expect(find.bySemanticsLabel('Modifica la valoració'), findsOneWidget);

    await tester.tap(find.text('Modifica'));
    await tester.pumpAndSettle();
    expect(find.text('Modifica la valoració'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('star-5')));
    await tester.pumpAndSettle();

    expect(viewModel.scoreFor('a1'), 5);
    expect(find.text('Ja has valorat aquesta activitat'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(5));
  });

  testWidgets('cancelling an edit keeps the rating', (tester) async {
    await rateFirst(tester, 3);
    await tester.tap(find.text('Modifica'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel·la'));
    await tester.pumpAndSettle();

    expect(viewModel.scoreFor('a1'), 3);
    expect(find.text('Ja has valorat aquesta activitat'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation and allows rating again', (
    tester,
  ) async {
    await rateFirst(tester, 4);

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar la valoració?'), findsOneWidget);

    await tester.tap(find.text('Cancel·la'));
    await tester.pumpAndSettle();
    expect(viewModel.hasRated('a1'), isTrue);

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Elimina'),
      ),
    );
    await tester.pumpAndSettle();

    expect(viewModel.hasRated('a1'), isFalse);
    expect(find.text('Com t’ha anat?'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('a rating made earlier can still be edited', (tester) async {
    final repository = DemoRatingRepository();
    await repository.rate(userId: 'u', activityId: 'a1', score: 2);
    viewModel = RatingViewModel(userId: 'u', repository: repository);
    addTearDown(viewModel.dispose);
    await viewModel.submit('a1', 1); // 409 -> rated, score unknown
    await pump(tester);

    await tester.tap(find.text('Modifica'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('star-4')));
    await tester.pumpAndSettle();

    expect(viewModel.scoreFor('a1'), 4);
  });
}
