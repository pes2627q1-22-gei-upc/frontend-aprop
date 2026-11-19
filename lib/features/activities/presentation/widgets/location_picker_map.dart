import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/geo_point.dart';
import '../../../../core/l10n/locale_controller.dart';

const _markerId = MarkerId('activity-location');
const _overviewZoom = 7.0;
const _placeZoom = 15.0;

/// Mapa petit per marcar on és l'activitat: tocar el mapa o arrossegar el
/// marcador canvia el punt. Quan [location] canvia des de fora (s'ha trobat el
/// municipi), la càmera s'hi mou.
class LocationPickerMap extends StatefulWidget {
  const LocationPickerMap({
    super.key,
    required this.location,
    required this.onChanged,
  });

  final GeoPoint? location;
  final ValueChanged<GeoPoint> onChanged;

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant LocationPickerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final location = widget.location;
    if (location == null || location == oldWidget.location) return;

    // La primera vegada que hi ha punt, s'hi acosta; després només s'hi mou.
    _controller?.animateCamera(
      oldWidget.location == null
          ? CameraUpdate.newLatLngZoom(_toLatLng(location), _placeZoom)
          : CameraUpdate.newLatLng(_toLatLng(location)),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = widget.location;

    return Semantics(
      label: context.l10n.pickerMapLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _toLatLng(location ?? cataloniaCenter),
                  zoom: location == null ? _overviewZoom : _placeZoom,
                ),
                onMapCreated: (controller) => _controller = controller,
                onTap: (point) => widget.onChanged(_toGeoPoint(point)),
                markers: {
                  if (location != null)
                    Marker(
                      markerId: _markerId,
                      position: _toLatLng(location),
                      draggable: true,
                      onDragEnd: (point) =>
                          widget.onChanged(_toGeoPoint(point)),
                    ),
                },
                // Dins del formulari desplaçable, el mapa es queda els gestos
                // per poder-lo moure i ampliar.
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    EagerGestureRecognizer.new,
                  ),
                },
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        context.l10n.pickerTapToAdjust,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static LatLng _toLatLng(GeoPoint point) =>
      LatLng(point.latitude, point.longitude);

  static GeoPoint _toGeoPoint(LatLng point) =>
      GeoPoint(latitude: point.latitude, longitude: point.longitude);
}
