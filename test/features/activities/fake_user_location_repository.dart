import 'dart:async';

import 'package:aprop/features/activities/models/user_position.dart';
import 'package:aprop/features/activities/repositories/user_location_repository.dart';

class FakeUserLocationRepository implements UserLocationRepository {
  FakeUserLocationRepository({this.access = LocationAccess.denied});

  /// Estat del permís abans de demanar-lo.
  LocationAccess access;

  /// Resposta de la persona en demanar-li el permís. Si és nul, no canvia.
  LocationAccess? answer;

  int requests = 0;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;

  final positions = StreamController<UserPosition>.broadcast();

  @override
  bool canOpenSettings = true;

  @override
  Future<LocationAccess> checkAccess() async => access;

  @override
  Future<LocationAccess> requestAccess() async {
    requests++;
    if (answer case final answer?) access = answer;
    return access;
  }

  @override
  Stream<UserPosition> watchPosition() => positions.stream;

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;

  @override
  Future<void> openLocationSettings() async => locationSettingsOpened++;
}
