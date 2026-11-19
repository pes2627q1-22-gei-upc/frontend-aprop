import 'package:aprop/features/ratings/presentation/widgets/star_rating_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, StarRatingWidget widget) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

void main() {
  testWidgets('reports the tapped star', (tester) async {
    int? selected;
    await _pump(tester, StarRatingWidget(onSelected: (s) => selected = s));

    await tester.tap(find.byKey(const ValueKey('star-4')));

    expect(selected, 4);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('fills the stars up to the score and exposes labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, StarRatingWidget(score: 3, onSelected: (_) {}));

    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    expect(find.bySemanticsLabel('Valora amb 1 estrella'), findsOneWidget);
    expect(find.bySemanticsLabel('Valora amb 5 estrelles'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('ignores taps while loading or already rated', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      StarRatingWidget(isLoading: true, onSelected: (_) => taps++),
    );
    await tester.tap(find.byKey(const ValueKey('star-2')));
    expect(taps, 0);

    await _pump(
      tester,
      StarRatingWidget(isReadOnly: true, onSelected: (_) => taps++),
    );
    await tester.tap(find.byKey(const ValueKey('star-2')));
    expect(taps, 0);
  });

  testWidgets('shows the error message', (tester) async {
    await _pump(
      tester,
      StarRatingWidget(onSelected: (_) {}, errorMessage: 'Error de prova'),
    );

    expect(find.text('Error de prova'), findsOneWidget);
  });
}
