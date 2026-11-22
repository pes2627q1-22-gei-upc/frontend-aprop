import 'package:aprop/features/activities/data/activity_json_mapper.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/activity_category_labels.dart';
import 'package:aprop/features/activities/models/activity_filters.dart';
import 'package:aprop/features/activities/presentation/formatters/activity_categories_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Per-language category dictionary (ca/es/en)', () {
    const knownGencatTags = <String, ({String ca, String es, String en})>{
      'agenda:categories/activitats-virtuals': (
        ca: 'Activitats virtuals',
        es: 'Actividades virtuales',
        en: 'Online activities',
      ),
      'agenda:categories/any-gaudi': (
        ca: 'Any Gaudí',
        es: 'Año Gaudí',
        en: 'Gaudí Year',
      ),
      'agenda:categories/carnavals': (
        ca: 'Carnavals',
        es: 'Carnavales',
        en: 'Carnivals',
      ),
      'agenda:categories/cicles': (ca: 'Cicles', es: 'Ciclos', en: 'Series'),
      'agenda:categories/circ': (ca: 'Circ', es: 'Circo', en: 'Circus'),
      'agenda:categories/commemoracions': (
        ca: 'Commemoracions',
        es: 'Conmemoraciones',
        en: 'Commemorations',
      ),
      'agenda:categories/concerts': (
        ca: 'Concerts',
        es: 'Conciertos',
        en: 'Concerts',
      ),
      'agenda:categories/conferencies': (
        ca: 'Conferències',
        es: 'Conferencias',
        en: 'Conferences',
      ),
      'agenda:categories/cultura-digital': (
        ca: 'Cultura digital',
        es: 'Cultura digital',
        en: 'Digital culture',
      ),
      'agenda:categories/cursos': (ca: 'Cursos', es: 'Cursos', en: 'Courses'),
      'agenda:categories/dansa': (ca: 'Dansa', es: 'Danza', en: 'Dance'),
      'agenda:categories/exposicions': (
        ca: 'Exposicions',
        es: 'Exposiciones',
        en: 'Exhibitions',
      ),
      'agenda:categories/festes': (
        ca: 'Festes',
        es: 'Fiestas',
        en: 'Festivities',
      ),
      'agenda:categories/festivals-i-mostres': (
        ca: 'Festivals i mostres',
        es: 'Festivales y muestras',
        en: 'Festivals & showcases',
      ),
      'agenda:categories/fires-i-mercats': (
        ca: 'Fires i mercats',
        es: 'Ferias y mercados',
        en: 'Fairs & markets',
      ),
      'agenda:categories/gegants': (
        ca: 'Gegants',
        es: 'Gigantes',
        en: 'Giants',
      ),
      'agenda:categories/infantil': (
        ca: 'Infantil',
        es: 'Infantil',
        en: 'Children',
      ),
      'agenda:categories/magia': (ca: 'Màgia', es: 'Magia', en: 'Magic'),
      'agenda:categories/nadal': (ca: 'Nadal', es: 'Navidad', en: 'Christmas'),
      'agenda:categories/opera': (ca: 'Òpera', es: 'Ópera', en: 'Opera'),
      'agenda:categories/rutes-i-visites': (
        ca: 'Rutes i visites',
        es: 'Rutas y visitas',
        en: 'Tours & visits',
      ),
      'agenda:categories/sardanes': (
        ca: 'Sardanes',
        es: 'Sardanas',
        en: 'Sardanes',
      ),
      'agenda:categories/setmana-santa': (
        ca: 'Setmana Santa',
        es: 'Semana Santa',
        en: 'Easter',
      ),
      'agenda:categories/teatre': (ca: 'Teatre', es: 'Teatro', en: 'Theatre'),
      'agenda:ambits/arts-visuals': (
        ca: 'Arts visuals',
        es: 'Artes visuales',
        en: 'Visual arts',
      ),
      'agenda:ambits/cinema': (ca: 'Cinema', es: 'Cine', en: 'Cinema'),
      'agenda:ambits/divulgacio': (
        ca: 'Divulgació',
        es: 'Divulgación',
        en: 'Outreach',
      ),
      'agenda:ambits/espectacles': (
        ca: 'Espectacles',
        es: 'Espectáculos',
        en: 'Performing arts',
      ),
      'agenda:ambits/gastronomia': (
        ca: 'Gastronomia',
        es: 'Gastronomía',
        en: 'Gastronomy',
      ),
      'agenda:ambits/llibres-i-lletres': (
        ca: 'Llibres i lletres',
        es: 'Libros y letras',
        en: 'Books & literature',
      ),
      'agenda:ambits/musica': (ca: 'Música', es: 'Música', en: 'Music'),
      'agenda:ambits/tradicional-i-popular': (
        ca: 'Tradicional i popular',
        es: 'Tradicional y popular',
        en: 'Traditional & folk',
      ),
      'agenda:ambits/za-any-europeu-patrimoni': (
        ca: 'Any Europeu del Patrimoni',
        es: 'Año Europeo del Patrimonio',
        en: 'European Year of Heritage',
      ),
      'agenda:ambits/zz-altres-ambits': (
        ca: 'Altres àmbits',
        es: 'Otros ámbitos',
        en: 'Other fields',
      ),
    };

    test('covers all 34 Gencat categories and ambits in ca, es and en', () {
      for (final MapEntry(key: raw, value: expected)
          in knownGencatTags.entries) {
        final ca = localizeActivityCategory(raw, languageCode: 'ca');
        final es = localizeActivityCategory(raw, languageCode: 'es');
        final en = localizeActivityCategory(raw, languageCode: 'en');
        expect(ca, expected.ca, reason: '$raw [ca]');
        expect(es, expected.es, reason: '$raw [es]');
        expect(en, expected.en, reason: '$raw [en]');
        for (final label in [ca, es, en]) {
          expect(label.contains('agenda:'), isFalse, reason: raw);
          expect(label.contains('/'), isFalse, reason: raw);
          expect(
            RegExp(r'^z[a-z]\b', caseSensitive: false).hasMatch(label),
            isFalse,
            reason: raw,
          );
        }
      }
    });

    test(
      'handles plain slugs, accented inputs and cross-language re-lookup',
      () {
        expect(activityCategoryLabel('musica'), 'Música');
        expect(
          localizeActivityCategory('Zz altres àmbits', languageCode: 'ca'),
          'Altres àmbits',
        );
        expect(
          localizeActivityCategory('Zz altres àmbits', languageCode: 'es'),
          'Otros ámbitos',
        );
        expect(
          localizeActivityCategory('Zz altres àmbits', languageCode: 'en'),
          'Other fields',
        );
        expect(
          localizeActivityCategory('Any gaudi', languageCode: 'ca'),
          'Any Gaudí',
        );
        expect(
          localizeActivityCategory('Espectacles', languageCode: 'es'),
          'Espectáculos',
        );
        expect(
          localizeActivityCategory('Espectacles', languageCode: 'en'),
          'Performing arts',
        );
        expect(
          localizeActivityCategory('Performing arts', languageCode: 'ca'),
          'Espectacles',
        );
        expect(
          localizeActivityCategory('Performing arts', languageCode: 'es'),
          'Espectáculos',
        );
        expect(
          localizeActivityCategory('Activitat', languageCode: 'en'),
          'Activity',
        );
        expect(
          localizeActivityCategory('Activitat', languageCode: 'es'),
          'Actividad',
        );
      },
    );

    test('prettifies unknown keys without raw prefixes or sort-key Zz', () {
      expect(
        localizeActivityCategory(
          'agenda:categories/zz-taller-de-cuina',
          languageCode: 'en',
        ),
        'Taller de Cuina',
      );
      expect(
        localizeActivityCategory(
          'agenda:ambits/za-nous-formats',
          languageCode: 'ca',
        ),
        'Nous Formats',
      );
      expect(
        localizeActivityCategory('Zz altres coses', languageCode: 'ca'),
        'Altres Coses',
      );
      expect(
        localizeActivityCategory('custom:jazz_club', languageCode: 'es'),
        'Jazz Club',
      );
      expect(localizeActivityCategory('agenda:categories/'), isEmpty);
      expect(localizeActivityCategory('   '), isEmpty);
      // Real words starting with z are preserved.
      expect(
        localizeActivityCategory('agenda:categories/zarzuela'),
        'Zarzuela',
      );
    });

    test('parseActivityCategories cleans and deduplicates equivalent tags', () {
      final parsed = parseActivityCategories([
        '',
        'agenda:categories/',
        'agenda:categories/musica',
        'agenda:ambits/musica',
        'musica',
        'agenda:ambits/zz-altres-ambits',
        'agenda:categories/any-gaudi',
      ]);
      expect(parsed, ['Música', 'Altres àmbits', 'Any Gaudí']);
    });

    test('sorts accented labels alphabetically', () {
      final labels = ['Òpera', 'Teatre', 'Altres àmbits', 'Nadal', 'Música']
        ..sort(compareActivityCategoryLabels);
      expect(labels, ['Altres àmbits', 'Música', 'Nadal', 'Òpera', 'Teatre']);
    });
  });

  group('Active filter prioritization and cross-language matching', () {
    test(
      'orderActivityCategoriesForFilter prioritizes matching filter first',
      () {
        final categories = [
          'Llibres i lletres',
          'Espectacles',
          'Concerts',
          'Cinema',
          'Altres àmbits',
        ];
        expect(orderActivityCategoriesForFilter(categories), categories);
        expect(
          orderActivityCategoriesForFilter(categories, const {'Concerts'}),
          [
            'Concerts',
            'Llibres i lletres',
            'Espectacles',
            'Cinema',
            'Altres àmbits',
          ],
        );
        // Matches across languages/raw keys as well.
        expect(
          orderActivityCategoriesForFilter(categories, const {
            'Performing arts',
          }).first,
          'Espectacles',
        );
      },
    );

    test('ActivityFilters matches categories across languages', () {
      final activity = Activity(
        id: '1',
        title: 'Show',
        category: 'Espectacles',
        categories: const ['Llibres i lletres', 'Espectacles'],
        municipality: 'Barcelona',
        startsAt: DateTime(2026, 11, 14),
        imageAsset: '',
        source: ActivitySource.culturalAgenda,
      );
      expect(
        ActivityFilters(categories: ['Performing arts']).matches(activity),
        isTrue,
      );
      expect(
        ActivityFilters(categories: ['Espectáculos']).matches(activity),
        isTrue,
      );
    });

    test('activityCategoriesLabel localizes and prioritizes active filter', () {
      final activity = Activity(
        id: '10',
        title: 'Festival',
        category: 'Llibres i lletres',
        categories: const ['Llibres i lletres', 'Espectacles', 'Concerts'],
        municipality: 'Barcelona',
        startsAt: DateTime(2026, 11, 14),
        imageAsset: '',
        source: ActivitySource.culturalAgenda,
      );

      expect(
        activityCategoriesLabel(activity, languageCode: 'en'),
        'Books & literature +2',
      );
      expect(
        activityCategoriesLabel(
          activity,
          activeFilterCategories: const {'Espectacles'},
          languageCode: 'en',
        ),
        'Performing arts +2',
      );
      expect(
        activityCategoriesLabel(
          activity,
          activeFilterCategories: const {'Espectacles'},
          languageCode: 'es',
        ),
        'Espectáculos +2',
      );
    });
  });
}
