import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/models/user_position.dart';
import 'package:aprop/features/activities/presentation/view_models/user_location_view_model.dart';
import 'package:aprop/features/activities/repositories/user_location_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_user_location_repository.dart';

void main() {
  const here = UserPosition(
    point: GeoPoint(latitude: 41.3874, longitude: 2.1686),
    accuracyMeters: 30,
  );

  late FakeUserLocationRepository repository;
  late UserLocationViewModel viewModel;

  UserLocationViewModel create({
    Duration locateTimeout = const Duration(seconds: 15),
  }) {
    viewModel = UserLocationViewModel(
      repository: repository,
      locateTimeout: locateTimeout,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  test('Amb el permís ja donat, mostra on ets sense preguntar res', () async {
    repository = FakeUserLocationRepository(access: LocationAccess.granted);
    create();

    await viewModel.show();
    repository.positions.add(here);
    await pumpEventQueue();

    expect(viewModel.position, here);
    expect(repository.requests, 0);
  });

  test('Sense permís, obrir el mapa no pregunta res ni escolta', () async {
    repository = FakeUserLocationRepository();
    create();

    await viewModel.show();

    expect(repository.requests, 0);
    expect(repository.positions.hasListener, isFalse);
    expect(viewModel.position, isNull);
  });

  test('El botó demana el permís i espera on ets', () async {
    repository = FakeUserLocationRepository()..answer = LocationAccess.granted;
    create();
    await viewModel.show();

    final locating = viewModel.locate();
    expect(viewModel.isLocating, isTrue);
    // Tornar a prémer el botó espera la mateixa cerca.
    expect(viewModel.locate(), same(locating));
    await pumpEventQueue();
    repository.positions.add(here);

    expect(await locating, LocateResult.located);
    expect(viewModel.position, here);
    expect(viewModel.isLocating, isFalse);
    expect(repository.requests, 1);
  });

  test('Si no hi ha permís o ubicació, diu per què', () async {
    for (final (answer, result) in [
      (LocationAccess.denied, LocateResult.denied),
      (LocationAccess.deniedForever, LocateResult.deniedForever),
      (LocationAccess.serviceDisabled, LocateResult.serviceDisabled),
    ]) {
      repository = FakeUserLocationRepository()..answer = answer;
      create();
      await viewModel.show();

      expect(await viewModel.locate(), result, reason: '$answer');
      expect(repository.positions.hasListener, isFalse, reason: '$answer');
    }
  });

  test('Si no arriba cap posició, no es queda esperant', () async {
    repository = FakeUserLocationRepository(access: LocationAccess.granted);
    create(locateTimeout: const Duration(milliseconds: 10));
    await viewModel.show();

    expect(await viewModel.locate(), LocateResult.unavailable);
    expect(viewModel.isLocating, isFalse);
  });

  test('Si la ubicació falla, deixa de mostrar on ets', () async {
    repository = FakeUserLocationRepository(access: LocationAccess.granted);
    create();
    await viewModel.show();
    repository.positions.add(here);
    await pumpEventQueue();

    repository.positions.addError(Exception('GPS'));
    await pumpEventQueue();

    expect(viewModel.position, isNull);
    expect(repository.positions.hasListener, isFalse);
  });

  test('En amagar el mapa, deixa d’escoltar per no gastar bateria', () async {
    repository = FakeUserLocationRepository(access: LocationAccess.granted);
    create();
    await viewModel.show();
    repository.positions.add(here);
    await pumpEventQueue();

    viewModel.hide();

    expect(repository.positions.hasListener, isFalse);
    expect(viewModel.position, isNull);
  });

  test(
    'Si s’amaga el mapa mentre busca, el botó no es queda esperant',
    () async {
      repository = FakeUserLocationRepository()
        ..answer = LocationAccess.granted;
      create();
      await viewModel.show();

      final locating = viewModel.locate();
      await pumpEventQueue();
      viewModel.hide();

      // No espera els 15 s del temps màxim.
      expect(
        await locating.timeout(const Duration(seconds: 1)),
        LocateResult.unavailable,
      );
      expect(viewModel.isLocating, isFalse);
    },
  );

  test('Si es tanca mentre busca, la cerca acaba igualment', () async {
    repository = FakeUserLocationRepository()..answer = LocationAccess.granted;
    final viewModel = UserLocationViewModel(repository: repository);
    await viewModel.show();

    final locating = viewModel.locate();
    await pumpEventQueue();
    viewModel.dispose();

    expect(
      await locating.timeout(const Duration(seconds: 1)),
      LocateResult.unavailable,
    );
    expect(repository.positions.hasListener, isFalse);
  });
}
