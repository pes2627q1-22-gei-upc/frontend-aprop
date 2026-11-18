import 'dart:math' as math;

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/models/geo_point.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_map_groups.dart';
import 'package:aprop/features/activities/presentation/widgets/map_group_icon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Activity _at(String id, double latitude, double longitude) => Activity(
  id: id,
  title: id,
  category: 'Música',
  municipality: 'Barcelona',
  startsAt: DateTime(2026, 11, 7, 19),
  imageAsset: '',
  source: ActivitySource.culturalAgenda,
  location: GeoPoint(latitude: latitude, longitude: longitude),
);

Set<String> _ids(List<ActivityMapGroup> groups) => {
  for (final group in groups) group.id,
};

void main() {
  final barcelona = _at('barcelona', 41.3881, 2.1874);
  final girona = _at('girona', 41.9858, 2.8249);
  final tarragona = _at('tarragona', 41.1146, 1.2593);

  test('Far apart they are separate; zoomed out, they overlap', () {
    expect(_ids(groupActivitiesForMap([barcelona, girona, tarragona], 7)), {
      'barcelona',
      'girona',
      'tarragona',
    });
    expect(_ids(groupActivitiesForMap([barcelona, girona, tarragona], 3)), {
      'grup:barcelona:3',
    });
  });

  test('The same place stays together even fully zoomed in', () {
    final other = _at('other', 41.3881, 2.1874);

    final groups = groupActivitiesForMap([barcelona, other], 21);

    expect(groups, hasLength(1));
    expect(isSamePlace(groups.single.bounds), isTrue);
  });

  test('The result does not depend on the order of the list', () {
    final nearby = _at('nearby', 41.40, 2.16);
    final activities = [girona, nearby, tarragona, barcelona];

    expect(
      _ids(groupActivitiesForMap(activities, 7)),
      _ids(groupActivitiesForMap(activities.reversed.toList(), 7)),
    );
    expect(_ids(groupActivitiesForMap(activities, 7)), {
      'grup:barcelona:2',
      'girona',
      'tarragona',
    });
  });

  test('A group has its centre and the area of all its activities', () {
    final nearby = _at('nearby', 41.40, 2.16);

    final group = groupActivitiesForMap([barcelona, nearby], 7).single;

    expect(group.center.latitude, closeTo((41.3881 + 41.40) / 2, 1e-9));
    expect(group.center.longitude, closeTo((2.1874 + 2.16) / 2, 1e-9));
    expect(group.bounds.southWest.latitude, 41.3881);
    expect(group.bounds.northEast.longitude, 2.1874);
    expect(isSamePlace(group.bounds), isFalse);
  });

  test('Activities without a location are left out', () {
    final unknown = Activity(
      id: 'unknown',
      title: 'Sense lloc',
      category: 'Música',
      municipality: '',
      startsAt: DateTime(2026, 11, 7),
      imageAsset: '',
      source: ActivitySource.community,
    );

    expect(_ids(groupActivitiesForMap([barcelona, unknown], 7)), {'barcelona'});
  });

  test('Markers never overlap, whatever the zoom', () {
    // Points spread around Barcelona, always the same ones.
    final random = math.Random(7);
    final activities = [
      for (var i = 0; i < 300; i++)
        _at(
          'a$i',
          41.2 + random.nextDouble() * 0.6,
          1.8 + random.nextDouble() * 0.8,
        ),
    ];

    math.Point<double> pixels(GeoPoint point, double zoom) {
      final scale = 256 * math.pow(2, zoom).toDouble();
      final sinLatitude = math.sin(point.latitude * math.pi / 180);
      return math.Point(
        (point.longitude + 180) / 360 * scale,
        (0.5 -
                math.log((1 + sinLatitude) / (1 - sinLatitude)) /
                    (4 * math.pi)) *
            scale,
      );
    }

    double size(ActivityMapGroup group) => group.isSingle
        ? 18
        : mapGroupDiameter(mapGroupLabel(group.activities.length)) / 2;

    for (final zoom in [6.0, 8.0, 9.5, 11.0, 13.0]) {
      final groups = groupActivitiesForMap(activities, zoom);
      expect(
        groups.fold(0, (total, group) => total + group.activities.length),
        300,
      );
      for (var i = 0; i < groups.length; i++) {
        for (var j = i + 1; j < groups.length; j++) {
          final distance = pixels(
            groups[i].center,
            zoom,
          ).distanceTo(pixels(groups[j].center, zoom));
          expect(
            distance,
            greaterThanOrEqualTo(size(groups[i]) + size(groups[j])),
            reason: 'zoom $zoom: ${groups[i].id} / ${groups[j].id}',
          );
        }
      }
    }
  });

  test('Groups always show the exact total', () {
    expect(mapGroupLabel(2), '2');
    expect(mapGroupLabel(150), '150');
    expect(mapGroupLabel(2019), '2019');
  });

  testWidgets('The group circle is drawn with the app colours', (tester) async {
    final colors = AppTheme.light.colorScheme;

    final icon = await tester.runAsync(
      () => drawMapGroupIcon(
        '12',
        fill: colors.primary,
        textColor: colors.onPrimary,
        border: colors.surface,
        devicePixelRatio: 2,
      ),
    );

    expect(icon, isA<BytesMapBitmap>());
    final bitmap = icon! as BytesMapBitmap;
    expect(bitmap.width, 44);
    expect(bitmap.byteData, isNotEmpty);
  });
}
