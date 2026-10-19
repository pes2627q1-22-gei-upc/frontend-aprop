import 'dart:async';

import 'package:aprop/features/activities/data/demo_activity_repository.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/new_activity.dart';
import 'package:aprop/features/activities/presentation/formatters/activity_price_formatter.dart';
import 'package:aprop/features/activities/presentation/view_models/create_activity_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_activity_repository.dart';

final now = DateTime(2026, 10, 19, 12);
const creator = ActivityCreator(name: 'Laia Soler', isFriend: false);
const jazzImage = 'assets/images/jazz_al_parc.jpg';

void main() {
  late FakeActivityRepository repository;
  late CreateActivityViewModel viewModel;

  setUp(() {
    repository = FakeActivityRepository();
    viewModel = CreateActivityViewModel(
      repository: repository,
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
      CreateActivityField.municipality,
      CreateActivityField.image,
    ]) {
      expect(viewModel.fieldError(field), isNotNull, reason: '$field');
    }
    expect(viewModel.fieldError(CreateActivityField.price), isNull);
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
    expect(viewModel.fieldError(CreateActivityField.image), isNull);
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
        category: 'Música',
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
}
