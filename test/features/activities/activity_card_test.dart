import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final activity = Activity(
    id: 'demo-jazz',
    title: 'Jazz al parc',
    category: 'Música',
    municipality: 'Barcelona',
    startsAt: DateTime(2026, 9, 26, 19),
    imageAsset: 'assets/images/jazz_al_parc.jpg',
    source: ActivitySource.culturalAgenda,
  );

  Future<List<String>> pumpCard(WidgetTester tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ActivityCard(
              activity: activity,
              onTap: () => taps.add('open'),
              participationAction: FilledButton(
                onPressed: () => taps.add('action'),
                child: const Text('Acció'),
              ),
            ),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('Tapping anywhere on the card opens the activity', (
    tester,
  ) async {
    final taps = await pumpCard(tester);

    await tester.tap(find.text('Barcelona'));
    await tester.tap(find.text('Jazz al parc'));
    await tester.tap(find.text('Font: Agenda Cultural · Generalitat'));

    expect(taps, ['open', 'open', 'open']);
  });

  testWidgets('Buttons inside the card do their own action', (tester) async {
    final taps = await pumpCard(tester);

    await tester.tap(find.text('Acció'));

    expect(taps, ['action']);
  });
  testWidgets('Amb diverses categories, mostra la primera i quantes més', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ActivityCard(
              activity: Activity(
                id: '101',
                title: 'Xerrada',
                category: 'Música',
                categories: const ['Música', 'Teatre', 'Conferències'],
                municipality: 'Girona',
                startsAt: DateTime(2026, 11, 14),
                imageAsset: '',
                source: ActivitySource.culturalAgenda,
                schedule: '18.00 h',
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Música'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('Teatre'), findsNothing);
    expect(find.textContaining('18.00 h'), findsOneWidget);
  });
}
