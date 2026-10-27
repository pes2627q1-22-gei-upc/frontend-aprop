import 'dart:async';

import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/geo_bounds.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/presentation/view_models/activities_map_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_activity_map_repository.dart';

void main() {
  const barcelona = GeoBounds(
    southWest: GeoPoint(latitude: 41.3, longitude: 2.0),
    northEast: GeoPoint(latitude: 41.5, longitude: 2.2),
  );
  const girona = GeoBounds(
    southWest: GeoPoint(latitude: 41.9, longitude: 2.7),
    northEast: GeoPoint(latitude: 42.1, longitude: 2.9),
  );

  Activity activity(String id) => Activity(
    id: id,
    title: 'Activitat $id',
    category: 'Música',
    municipality: 'Barcelona',
    startsAt: DateTime(2026, 11, 7),
    imageAsset: '',
    source: ActivitySource.culturalAgenda,
    location: cataloniaCenter,
  );

  late FakeActivityMapRepository repository;
  late ActivitiesMapViewModel viewModel;

  setUp(() {
    repository = FakeActivityMapRepository();
    viewModel = ActivitiesMapViewModel(repository: repository);
  });

  tearDown(() => viewModel.dispose());

  test(
    'Carrega la zona visible amb marge i en mostra les activitats',
    () async {
      repository.activities = [activity('1')];

      final load = viewModel.loadArea(barcelona);
      expect(viewModel.isLoading, isTrue);
      await load;

      expect(repository.requestedAreas, [
        barcelona.expandedBy(ActivitiesMapViewModel.areaMargin),
      ]);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.activities.map((a) => a.id), ['1']);
    },
  );

  test(
    'Moure el mapa dins de la zona carregada no torna a demanar res',
    () async {
      await viewModel.loadArea(barcelona);
      const smaller = GeoBounds(
        southWest: GeoPoint(latitude: 41.35, longitude: 2.05),
        northEast: GeoPoint(latitude: 41.55, longitude: 2.25),
      );
      await viewModel.loadArea(smaller);

      expect(repository.requestedAreas, hasLength(1));
    },
  );

  test(
    'Si falla, ho diu, conserva les activitats i es pot tornar a provar',
    () async {
      repository.activities = [activity('1')];
      await viewModel.loadArea(barcelona);

      repository.loadArea = (_) => Future.error(Exception('sense xarxa'));
      await viewModel.loadArea(girona);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.activities.map((a) => a.id), ['1']);

      repository.loadArea = (_) async => [activity('2')];
      await viewModel.retry();
      expect(repository.requestedAreas.last, girona.expandedBy(0.5));
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.activities.map((a) => a.id), ['2']);
    },
  );

  test(
    'En refrescar torna a demanar la zona visible encara que ja hi fos',
    () async {
      await viewModel.loadArea(barcelona);

      repository.activities = [activity('nova')];
      await viewModel.refresh();

      expect(repository.requestedAreas, hasLength(2));
      expect(viewModel.activities.map((a) => a.id), ['nova']);
    },
  );

  test('Una resposta que arriba tard no tapa la de la zona actual', () async {
    final slow = Completer<List<Activity>>();
    repository.loadArea = (area) => area == barcelona.expandedBy(0.5)
        ? slow.future
        : Future.value([activity('girona')]);

    final first = viewModel.loadArea(barcelona);
    await viewModel.loadArea(girona);
    slow.complete([activity('barcelona')]);
    await first;

    expect(viewModel.activities.map((a) => a.id), ['girona']);
    expect(viewModel.isLoading, isFalse);
  });
}
