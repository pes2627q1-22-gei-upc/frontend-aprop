import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_card.dart';
import 'package:aprop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  testWidgets(
    'Amb filtre de categoria actiu, mostra primer la categoria coincident i +N',
    (tester) async {
      final multiCategory = Activity(
        id: '102',
        title: 'Festival de tardor',
        category: 'Llibres i lletres',
        categories: const [
          'Llibres i lletres',
          'Arts visuals',
          'Divulgació',
          'Espectacles',
          'Concerts',
          'Cinema',
          'Teatre',
          'Dansa',
          'Any Gaudí',
          'Altres àmbits',
        ],
        municipality: 'Barcelona',
        startsAt: DateTime(2026, 11, 14),
        imageAsset: '',
        source: ActivitySource.culturalAgenda,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActivityCard(
                activity: multiCategory,
                preferredCategories: const {'Concerts', 'Cinema'},
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Concerts'), findsOneWidget);
      expect(find.text('+9'), findsOneWidget);
      expect(find.text('Llibres i lletres'), findsNothing);
    },
  );

  testWidgets('Tradueix les categories de la targeta en castellà i anglès', (
    tester,
  ) async {
    final activityWithAmbits = Activity(
      id: '103',
      title: 'Gala cultural',
      category: 'Espectacles',
      categories: const ['Espectacles', 'Altres àmbits'],
      municipality: 'Girona',
      startsAt: DateTime(2026, 11, 14),
      imageAsset: '',
      source: ActivitySource.culturalAgenda,
    );

    Widget buildLocalized(Locale locale) => MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: ActivityCard(activity: activityWithAmbits, onTap: () {}),
        ),
      ),
    );

    await tester.pumpWidget(buildLocalized(const Locale('es')));
    await tester.pumpAndSettle();
    expect(find.text('Espectáculos'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);

    await tester.pumpWidget(buildLocalized(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Performing arts'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
  });
}
