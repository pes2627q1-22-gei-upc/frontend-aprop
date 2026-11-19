import 'dart:async';

import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/data/demo_location_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/activity_category.dart';
import 'package:aprop/features/activities/models/activity_options.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/models/new_activity.dart';
import 'package:aprop/features/activities/presentation/formatters/activity_price_formatter.dart';
import 'package:aprop/features/activities/presentation/view_models/create_activity_view_model.dart';
import 'package:aprop/features/activities/repositories/activity_category_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_activity_repository.dart';

final now = DateTime(2026, 10, 19, 12);
const creator = ActivityCreator(name: 'Laia Soler', isFriend: false);
const jazzImage = 'assets/images/jazz_al_parc.jpg';
const vic = GeoPoint(latitude: 41.9301, longitude: 2.2549);
const girona = GeoPoint(latitude: 41.9794, longitude: 2.8214);
const mainSquare = GeoPoint(latitude: 41.9300, longitude: 2.2545);

void main() {
  late FakeActivityRepository repository;
  late CreateActivityViewModel viewModel;

  setUp(() {
    repository = FakeActivityRepository();
    viewModel = CreateActivityViewModel(
      repository: repository,
      locationRepository: const DemoLocationRepository(),
      creator: creator,
      now: () => now,
    );
  });

  tearDown(() => viewModel.dispose());

  Future<Activity?> publishValid({String price = ''}) {
    viewModel
      ..setCategory('Música')
      ..setStartsAt(DateTime(2026, 11, 1, 19))
      ..setImageAsset(jazzImage);
    return viewModel.publish(
      title: ' Concert a la plaça ',
      description: ' Una nit de música ',
      municipality: ' Vic ',
      price: price,
    );
  }

  test('Publica una activitat no oficial amb les dades netes', () async {
    final activity = await publishValid();

    expect(activity, isNotNull);
    expect(activity!.source, ActivitySource.community);
    final sent = repository.created.single;
    expect(sent.title, 'Concert a la plaça');
    expect(sent.description, 'Una nit de música');
    expect(sent.municipality, 'Vic');
    expect(sent.category, 'Música');
    expect(sent.startsAt, DateTime(2026, 11, 1, 19));
    expect(sent.imageAsset, jazzImage);
    expect(sent.price, 0);
    expect(sent.creator, same(creator));
    expect(viewModel.isPublishing, isFalse);
  });

  test('No publica si falten camps obligatoris', () async {
    final activity = await viewModel.publish(
      title: ' ',
      description: '',
      municipality: '',
      price: '',
    );

    expect(activity, isNull);
    expect(repository.created, isEmpty);
    for (final field in [
      CreateActivityField.title,
      CreateActivityField.description,
      CreateActivityField.category,
      CreateActivityField.startsAt,
    ]) {
      expect(viewModel.fieldError(field), isNotNull, reason: '$field');
    }
    expect(viewModel.fieldError(CreateActivityField.price), isNull);
    expect(viewModel.fieldError(CreateActivityField.endsAt), isNull);
  });

  test('El municipi és opcional', () async {
    viewModel
      ..setCategory('Música')
      ..setStartsAt(DateTime(2026, 11, 1, 19));

    final activity = await viewModel.publish(
      title: 'Concert',
      description: 'Una nit',
      municipality: '   ',
      price: '',
    );

    expect(activity, isNotNull);
    expect(repository.created.single.municipality, isEmpty);
  });

  group('Data de fi', () {
    test('És opcional: sense indicar-la no se n’envia cap', () async {
      await publishValid();

      expect(repository.created.single.endsAt, isNull);
    });

    test('Desa la data de fi posterior a l’inici', () async {
      viewModel.setEndsAt(DateTime(2026, 11, 1, 22));
      await publishValid();

      expect(repository.created.single.endsAt, DateTime(2026, 11, 1, 22));
    });

    test('Rebutja una fi que no és posterior a l’inici', () async {
      viewModel.setEndsAt(DateTime(2026, 11, 1, 19));
      await publishValid();

      expect(
        viewModel.fieldError(CreateActivityField.endsAt),
        'La fi ha de ser posterior a l’inici.',
      );
      expect(repository.created, isEmpty);

      viewModel.setEndsAt(null);
      expect(viewModel.fieldError(CreateActivityField.endsAt), isNull);
      await publishValid();
      expect(repository.created.single.endsAt, isNull);
    });
  });

  test('L’inici ha de ser posterior al moment de crear-la', () async {
    viewModel
      ..setCategory('Música')
      ..setImageAsset(jazzImage)
      ..setStartsAt(now);

    await viewModel.publish(
      title: 'Concert',
      description: 'Una nit',
      municipality: 'Vic',
      price: '',
    );

    expect(
      viewModel.fieldError(CreateActivityField.startsAt),
      'L’inici ha de ser posterior a ara.',
    );
    expect(repository.created, isEmpty);
  });

  test('Desa les indicacions netes; buides queden nul·les', () async {
    viewModel
      ..setCategory('Música')
      ..setStartsAt(DateTime(2026, 11, 1, 19))
      ..setImageAsset(jazzImage);

    await viewModel.publish(
      title: 'Concert',
      description: 'Una nit',
      municipality: 'Vic',
      price: '',
      directions: '  Entrada pel pati, 2n pis  ',
    );
    await viewModel.publish(
      title: 'Concert',
      description: 'Una nit',
      municipality: 'Vic',
      price: '',
      directions: '   ',
    );

    expect(repository.created.first.directions, 'Entrada pel pati, 2n pis');
    expect(repository.created.last.directions, isNull);
  });

  test('Per defecte la portada és la primera plantilla', () async {
    expect(viewModel.imageAsset, activityImageTemplates.first);

    viewModel
      ..setCategory('Música')
      ..setStartsAt(DateTime(2026, 11, 1, 19));
    await viewModel.publish(
      title: 'Concert',
      description: 'Una nit',
      municipality: 'Vic',
      price: '',
    );

    expect(repository.created.single.imageAsset, activityImageTemplates.first);
  });

  group('Ubicació al mapa', () {
    test('En trobar el municipi hi posa el marcador', () async {
      expect(viewModel.location, isNull);

      await viewModel.locateMunicipality(' Vic ');

      expect(viewModel.location, vic);
      expect(viewModel.isLocationApproximate, isTrue);
    });

    test('Es pot ajustar el marcador i es desa en publicar', () async {
      await viewModel.locateMunicipality('Vic');
      viewModel.setLocation(mainSquare);

      expect(viewModel.isLocationApproximate, isFalse);
      await publishValid();
      expect(repository.created.single.location, mainSquare);
    });

    test('Mentre s’escriu, el marcador ajustat no es perd', () async {
      await viewModel.locateMunicipality('Vic');
      viewModel.setLocation(mainSquare);

      // «Vic» → «Vic,» no és cap municipi conegut; tornar a «Vic» tampoc no
      // ha de moure el marcador ajustat.
      await viewModel.locateMunicipality('Vic,');
      expect(viewModel.location, mainSquare);
    });

    test('Un municipi nou mou el marcador', () async {
      await viewModel.locateMunicipality('Vic');
      viewModel.setLocation(mainSquare);

      await viewModel.locateMunicipality('Girona');

      expect(viewModel.location, girona);
    });

    test('Si el municipi no es coneix, no inventa cap punt', () async {
      await viewModel.locateMunicipality('Poble inventat');

      expect(viewModel.location, isNull);
      await publishValid();
      expect(repository.created.single.location, isNull);
    });

    test('Troba els municipis sense accents ni majúscules', () async {
      const locations = DemoLocationRepository();

      expect(
        await locations.findMunicipality('MATARO'),
        await locations.findMunicipality('Mataró'),
      );
      expect(await locations.findMunicipality('Mataró'), isNotNull);
    });
  });

  test('Desa el preu indicat', () async {
    await publishValid(price: '12,50');

    expect(repository.created.single.price, 12.5);
  });

  test('Rebutja un preu que no és un import', () async {
    await publishValid(price: 'dotze');

    expect(viewModel.fieldError(CreateActivityField.price), isNotNull);
    expect(repository.created, isEmpty);
  });

  test('En modificar un camp se n’esborra l’error', () async {
    await viewModel.publish(
      title: '',
      description: '',
      municipality: '',
      price: '',
    );

    viewModel
      ..onFieldChanged(CreateActivityField.title)
      ..setCategory('Teatre')
      ..setImageAsset(jazzImage);

    expect(viewModel.fieldError(CreateActivityField.title), isNull);
    expect(viewModel.fieldError(CreateActivityField.category), isNull);
    expect(viewModel.fieldError(CreateActivityField.description), isNotNull);
  });

  test('Si la publicació falla, ho explica', () async {
    repository.createError = Exception('Offline');

    final activity = await publishValid();

    expect(activity, isNull);
    expect(viewModel.errorMessage, createActivityErrorMessage);
    expect(viewModel.isPublishing, isFalse);
  });

  test('No publica dues vegades si es prem mentre envia', () async {
    repository.pendingCreate = Completer<void>();

    final first = publishValid();
    await viewModel.publish(
      title: 'Concert',
      description: 'Una nit',
      municipality: 'Vic',
      price: '',
    );
    expect(viewModel.isPublishing, isTrue);

    repository.pendingCreate!.complete();
    await first;
    expect(repository.created, hasLength(1));
  });

  test('Interpreta i formata els preus', () {
    expect(parseActivityPrice(''), 0);
    expect(parseActivityPrice('12'), 12);
    expect(parseActivityPrice('12,5'), 12.5);
    expect(parseActivityPrice(' 12.50 '), 12.5);
    expect(parseActivityPrice('-3'), isNull);
    expect(parseActivityPrice('1,234'), isNull);
    expect(parseActivityPrice('dotze'), isNull);

    expect(formatActivityPrice(0), 'Gratuït');
    expect(formatActivityPrice(12), '12 €');
    expect(formatActivityPrice(12.5), '12,50 €');
  });

  test('El repositori de demostració afegeix l’activitat al catàleg', () async {
    final demo = DemoActivityRepository();

    final created = await demo.createActivity(
      NewActivity(
        title: 'Concert a la plaça',
        description: 'Una nit de música',
        categories: ['Música'],
        startsAt: DateTime(2026, 9, 26, 12),
        municipality: 'Vic',
        imageAsset: jazzImage,
        creator: creator,
        price: 5,
      ),
    );

    final activities = await demo.getActivities();
    // Ordenades per data: el 26 de setembre a les 12 va abans del jazz.
    expect(activities.first.id, created.id);
    expect(await demo.getActivityById(created.id), same(created));
    expect(created.source, ActivitySource.community);
    expect(created.creator?.name, 'Laia Soler');
  });

  group('Categories', () {
    CreateActivityViewModel withCategories(_FakeCategoryRepository source) =>
        CreateActivityViewModel(
          repository: repository,
          locationRepository: const DemoLocationRepository(),
          creator: creator,
          categoryRepository: source,
          now: () => now,
        );

    test('Sense repositori, ofereix la llista provisional', () {
      expect(viewModel.categories.map((c) => c.label), activityCategories);
    });

    test('Les carrega del repositori i desa el valor de la triada', () async {
      final source = _FakeCategoryRepository();
      final viewModel = withCategories(source);
      addTearDown(viewModel.dispose);

      final load = viewModel.loadCategories();
      expect(viewModel.isLoadingCategories, isTrue);
      await load;

      expect(viewModel.isLoadingCategories, isFalse);
      expect(viewModel.categories.map((c) => c.label), ['Teatre']);
      viewModel.setCategory(viewModel.categories.single.value);
      expect(viewModel.category, 'agenda:categories/teatre');
    });

    test('Si fallen, ho diu i es pot tornar a provar', () async {
      final source = _FakeCategoryRepository()..fail = true;
      final viewModel = withCategories(source);
      addTearDown(viewModel.dispose);

      await viewModel.loadCategories();
      expect(viewModel.categoriesError, isNotNull);
      expect(viewModel.categories, isEmpty);

      source.fail = false;
      await viewModel.loadCategories();
      expect(viewModel.categoriesError, isNull);
      expect(viewModel.categories, hasLength(1));
    });
  });

  group('Editar', () {
    final existing = Activity(
      id: 'demo-created-1',
      title: 'Concert a la plaça',
      category: 'Música',
      municipality: 'Vic',
      startsAt: DateTime(2026, 11, 1, 19),
      endsAt: DateTime(2026, 11, 1, 21),
      imageAsset: jazzImage,
      source: ActivitySource.community,
      creator: creator,
      description: 'Una nit de música',
      location: mainSquare,
      price: 5,
    );

    CreateActivityViewModel editing(
      Activity activity, {
      ActivityCategoryRepository? categories,
    }) {
      final viewModel = CreateActivityViewModel(
        repository: repository,
        locationRepository: const DemoLocationRepository(),
        creator: creator,
        categoryRepository: categories,
        now: () => now,
        editing: activity,
      );
      addTearDown(viewModel.dispose);
      return viewModel;
    }

    test('Comença amb el que ja tenia l’activitat', () {
      final viewModel = editing(existing);

      expect(viewModel.isEditing, isTrue);
      expect(viewModel.hasUnknownPrice, isFalse);
      expect(viewModel.category, 'Música');
      expect(viewModel.startsAt, DateTime(2026, 11, 1, 19));
      expect(viewModel.endsAt, DateTime(2026, 11, 1, 21));
      expect(viewModel.imageAsset, jazzImage);
      expect(viewModel.location, mainSquare);
    });

    test('Desa els canvis a la mateixa activitat', () async {
      final viewModel = editing(existing);

      final saved = await viewModel.publish(
        title: 'Concert al parc',
        description: 'Una nit de música',
        municipality: 'Vic',
        price: '5',
      );

      expect(saved, isNotNull);
      expect(repository.created, isEmpty);
      final (id, sent) = repository.updated.single;
      expect(id, 'demo-created-1');
      expect(sent.title, 'Concert al parc');
      expect(sent.endsAt, DateTime(2026, 11, 1, 21));
      expect(sent.location, mainSquare);
    });

    test('Tria la categoria del backend pel nom que es veu', () async {
      final viewModel = editing(
        Activity(
          id: '506',
          title: 'Obra',
          category: 'Teatre',
          municipality: '',
          startsAt: DateTime(2026, 11, 1, 19),
          imageAsset: '',
          source: ActivitySource.community,
        ),
        categories: _FakeCategoryRepository(),
      );

      await viewModel.loadCategories();

      expect(viewModel.category, 'agenda:categories/teatre');
    });

    test(
      'Si el preu no se sap i no es toca, no passa a ser gratuïta',
      () async {
        final unknownPrice = Activity(
          id: '506',
          title: 'Obra',
          category: 'Música',
          municipality: '',
          startsAt: DateTime(2026, 11, 1, 19),
          imageAsset: '',
          source: ActivitySource.community,
        );

        final viewModel = editing(unknownPrice);
        expect(viewModel.hasUnknownPrice, isTrue);
        await viewModel.publish(
          title: 'Obra',
          description: 'Descripció',
          price: '',
        );

        expect(repository.updated.single.$2.price, isNull);
      },
    );

    test('Si no es pot desar, ho explica', () async {
      repository.updateError = Exception('403');
      final viewModel = editing(existing);

      final saved = await viewModel.publish(
        title: 'Concert',
        description: 'Una nit',
        price: '',
      );

      expect(saved, isNull);
      expect(viewModel.errorMessage, updateActivityErrorMessage);
    });
  });
  group('Diverses categories', () {
    test('Se n’hi poden triar fins a tres, en l’ordre triat', () async {
      viewModel
        ..toggleCategory('Teatre')
        ..toggleCategory('Música')
        ..toggleCategory('Exposicions')
        ..toggleCategory('Cinema');

      expect(viewModel.selectedCategories, ['Teatre', 'Música', 'Exposicions']);
      expect(
        viewModel.fieldError(CreateActivityField.category),
        'Pots triar fins a 3 categories.',
      );

      viewModel.toggleCategory('Teatre');
      expect(viewModel.selectedCategories, ['Música', 'Exposicions']);
      expect(viewModel.fieldError(CreateActivityField.category), isNull);

      viewModel
        ..setStartsAt(DateTime(2026, 11, 1, 19))
        ..setImageAsset(jazzImage);
      await viewModel.publish(
        price: '',
        title: 'Concert',
        description: 'Música',
      );
      expect(repository.created.single.categories, ['Música', 'Exposicions']);
      expect(repository.created.single.category, 'Música');
    });

    test('Sense cap categoria no es publica', () async {
      viewModel
        ..toggleCategory('Música')
        ..toggleCategory('Música')
        ..setStartsAt(DateTime(2026, 11, 1, 19));

      expect(
        await viewModel.publish(
          price: '',
          title: 'Concert',
          description: 'Música',
        ),
        isNull,
      );
      expect(
        viewModel.fieldError(CreateActivityField.category),
        'Tria una categoria.',
      );
    });
  });

  group('Horari', () {
    test('Es genera amb l’hora d’inici', () async {
      await publishValid();

      expect(repository.created.single.schedule, '19.00 h');
    });

    test('Hi afegeix l’hora de fi i la nota opcional', () async {
      viewModel
        ..setCategory('Música')
        ..setStartsAt(DateTime(2026, 11, 1, 19, 30))
        ..setEndsAt(DateTime(2026, 11, 1, 21))
        ..setImageAsset(jazzImage);

      await viewModel.publish(
        price: '',
        title: 'Concert',
        description: 'Música',
        scheduleNote: '  Porta oberta mitja hora abans ',
      );

      expect(
        repository.created.single.schedule,
        '19.30 h – 21.00 h · Porta oberta mitja hora abans',
      );
    });

    test('Si acaba un altre dia, només hi posa l’inici', () {
      expect(
        activityScheduleTime(
          DateTime(2026, 11, 1, 9, 5),
          DateTime(2026, 11, 3, 18),
        ),
        '09.05 h',
      );
    });
  });

  group('Modalitat i permanència', () {
    test('Per defecte és presencial i no permanent', () async {
      await publishValid();

      final sent = repository.created.single;
      expect(sent.modality, ActivityModality.inPerson);
      expect(sent.isPermanent, isFalse);
      expect(sent.onlineUrl, isNull);
    });

    test('En línia desa l’enllaç i si és permanent', () async {
      viewModel
        ..setModality(ActivityModality.online)
        ..setPermanent(true)
        ..setCategory('Música')
        ..setStartsAt(DateTime(2026, 11, 1, 19))
        ..setImageAsset(jazzImage);

      await viewModel.publish(
        price: '',
        title: 'Xerrada',
        description: 'En directe',
        onlineUrl: ' https://meet.example.cat/xerrada ',
      );

      final sent = repository.created.single;
      expect(sent.modality, ActivityModality.online);
      expect(sent.isPermanent, isTrue);
      expect(sent.onlineUrl, 'https://meet.example.cat/xerrada');
    });

    test('Rebutja un enllaç que no és una adreça web', () async {
      viewModel
        ..setModality(ActivityModality.mixed)
        ..setCategory('Música')
        ..setStartsAt(DateTime(2026, 11, 1, 19))
        ..setImageAsset(jazzImage);

      final activity = await viewModel.publish(
        price: '',
        title: 'Xerrada',
        description: 'En directe',
        onlineUrl: 'meet a la plaça',
      );

      expect(activity, isNull);
      expect(repository.created, isEmpty);
      expect(
        viewModel.fieldError(CreateActivityField.onlineUrl),
        'Introdueix un enllaç que comenci per https://.',
      );
    });

    test('Si torna a ser presencial, l’enllaç no s’envia', () async {
      viewModel
        ..setModality(ActivityModality.online)
        ..setModality(ActivityModality.inPerson)
        ..setCategory('Música')
        ..setStartsAt(DateTime(2026, 11, 1, 19))
        ..setImageAsset(jazzImage);

      await viewModel.publish(
        price: '',
        title: 'Concert',
        description: 'Música',
        onlineUrl: 'no és un enllaç',
      );

      expect(repository.created.single.onlineUrl, isNull);
    });
  });

  group('Editar la informació extra', () {
    final existing = Activity(
      id: 'demo-created-2',
      title: 'Xerrada',
      category: 'Música',
      categories: const ['Música', 'Teatre'],
      municipality: 'Vic',
      startsAt: DateTime(2026, 11, 1, 19),
      endsAt: DateTime(2026, 11, 1, 21),
      imageAsset: jazzImage,
      source: ActivitySource.community,
      creator: creator,
      schedule: '19.00 – 21.00 h · Porta cadira',
      modality: ActivityModality.mixed,
      isPermanent: true,
      onlineUrl: 'https://meet.example.cat/xerrada',
    );

    CreateActivityViewModel editing(Activity activity) {
      final viewModel = CreateActivityViewModel(
        repository: repository,
        locationRepository: const DemoLocationRepository(),
        creator: creator,
        now: () => now,
        editing: activity,
      );
      addTearDown(viewModel.dispose);
      return viewModel;
    }

    test('Comença amb les categories, la modalitat i la nota', () {
      final viewModel = editing(existing);

      expect(viewModel.selectedCategories, ['Música', 'Teatre']);
      expect(viewModel.modality, ActivityModality.mixed);
      expect(viewModel.isPermanent, isTrue);
      expect(viewModel.initialScheduleNote, 'Porta cadira');
    });

    test('Un horari escrit d’una altra manera es conserva com a nota', () {
      final viewModel = editing(
        Activity(
          id: '506',
          title: 'Exposició',
          category: 'Exposicions',
          municipality: '',
          startsAt: DateTime(2026, 11, 1),
          imageAsset: '',
          source: ActivitySource.community,
          schedule: 'De dimarts a diumenge, de 10 a 14 h',
        ),
      );

      expect(
        viewModel.initialScheduleNote,
        'De dimarts a diumenge, de 10 a 14 h',
      );
    });

    test('Si l’horari és només l’hora generada, no hi ha nota', () {
      final viewModel = editing(
        Activity(
          id: '507',
          title: 'Concert',
          category: 'Música',
          municipality: '',
          startsAt: DateTime(2026, 11, 1, 19),
          imageAsset: '',
          source: ActivitySource.community,
          schedule: '19.00 h',
        ),
      );

      expect(viewModel.initialScheduleNote, isEmpty);
    });
  });
  group('Editar una activitat del backend (sense hora a la data)', () {
    // El backend només desa el dia: la data arriba a les 00.00 (DP-029).
    Activity fromBackend(String? schedule, {DateTime? endsAt}) => Activity(
      id: '506',
      title: 'Concert',
      category: 'Música',
      municipality: 'Vic',
      startsAt: DateTime(2026, 11, 1),
      endsAt: endsAt,
      imageAsset: jazzImage,
      source: ActivitySource.community,
      creator: creator,
      schedule: schedule,
    );

    CreateActivityViewModel editing(Activity activity) {
      final viewModel = CreateActivityViewModel(
        repository: repository,
        locationRepository: const DemoLocationRepository(),
        creator: creator,
        now: () => now,
        editing: activity,
      );
      addTearDown(viewModel.dispose);
      return viewModel;
    }

    test('Recupera l’hora de l’horari i no la repeteix en desar', () async {
      final viewModel = editing(fromBackend('19.00 h · Durada: 1 h'));

      expect(viewModel.startsAt, DateTime(2026, 11, 1, 19));
      expect(viewModel.initialScheduleNote, 'Durada: 1 h');

      await viewModel.publish(
        title: 'Concert',
        description: 'Música',
        price: '',
        scheduleNote: viewModel.initialScheduleNote,
      );

      final (_, sent) = repository.updated.single;
      expect(sent.startsAt, DateTime(2026, 11, 1, 19));
      expect(sent.schedule, '19.00 h · Durada: 1 h');
    });

    test('També en recupera l’hora de fi', () {
      final viewModel = editing(
        fromBackend('18.00 h – 20.30 h', endsAt: DateTime(2026, 11, 1)),
      );

      expect(viewModel.startsAt, DateTime(2026, 11, 1, 18));
      expect(viewModel.endsAt, DateTime(2026, 11, 1, 20, 30));
      expect(viewModel.initialScheduleNote, isEmpty);
    });

    test('Llegeix l’hora en el format de qualsevol idioma', () {
      expect(parseActivityScheduleTime('19:00 h')?.start, (
        hour: 19,
        minute: 0,
      ));
      expect(parseActivityScheduleTime('7:05 – 9:00 · Nota'), (
        start: (hour: 7, minute: 5),
        end: (hour: 9, minute: 0),
        note: 'Nota',
      ));
      // Un horari escrit a mà no és una hora generada.
      expect(parseActivityScheduleTime('10.00 h a 14.00 h'), isNull);
      expect(parseActivityScheduleTime('De dimarts a diumenge'), isNull);
    });

    test('Sense hora a l’horari, la data es queda com estava', () {
      final viewModel = editing(fromBackend('De dimarts a diumenge'));

      expect(viewModel.startsAt, DateTime(2026, 11, 1));
      expect(viewModel.initialScheduleNote, 'De dimarts a diumenge');
    });
  });
}

class _FakeCategoryRepository implements ActivityCategoryRepository {
  bool fail = false;

  @override
  Future<List<ActivityCategory>> getCreationCategories() async {
    if (fail) throw Exception('Offline');
    return const [
      ActivityCategory(value: 'agenda:categories/teatre', label: 'Teatre'),
    ];
  }
}
