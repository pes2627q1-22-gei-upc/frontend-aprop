import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/activity.dart';
import '../../models/geo_bounds.dart';
import '../../models/geo_point.dart';
import '../formatters/activity_date_formatter.dart';
import 'activity_badges.dart';
import 'activity_information_row.dart';

const _clusterManagerId = ClusterManagerId('activities');

/// Durada de les transicions de la targeta i dels botons que s'hi aparten.
const mapOverlayAnimationDuration = Duration(milliseconds: 280);
const _overlayCurve = Curves.easeOutCubic;
const _cardMargin = 12.0;
const _initialZoom = 7.0;

/// Tipus de marcador: oficial (Agenda Cultural), d'un usuari o d'una amistat.
enum ActivityMarkerKind { official, community, friend }

ActivityMarkerKind activityMarkerKind(Activity activity) {
  if (activity.source == ActivitySource.culturalAgenda) {
    return ActivityMarkerKind.official;
  }
  return (activity.creator?.isFriend ?? false)
      ? ActivityMarkerKind.friend
      : ActivityMarkerKind.community;
}

const activityMarkerAssets = {
  ActivityMarkerKind.official: 'assets/icons/marker_official.png',
  ActivityMarkerKind.community: 'assets/icons/marker_community.png',
  ActivityMarkerKind.friend: 'assets/icons/marker_friend.png',
};

/// Mapa d'Inici (fig. 7): un marcador per activitat amb ubicació, agrupats amb
/// un número quan són a prop. Tocar-ne un mostra una targeta resumida amb
/// «Veure activitat».
class ActivitiesMap extends StatefulWidget {
  const ActivitiesMap({
    super.key,
    required this.activities,
    required this.onActivitySelected,
    this.onOverlayHeightChanged,
    this.onVisibleAreaChanged,
  });

  final List<Activity> activities;
  final ValueChanged<String> onActivitySelected;

  /// Espai que ocupa la targeta del marcador des de baix (0 si no n'hi ha),
  /// perquè qui conté el mapa pugui apartar-hi els seus botons.
  final ValueChanged<double>? onOverlayHeightChanged;

  /// Zona visible en obrir el mapa i cada cop que s'acaba de moure, per
  /// carregar-ne les activitats.
  final ValueChanged<GeoBounds>? onVisibleAreaChanged;

  @override
  State<ActivitiesMap> createState() => _ActivitiesMapState();
}

class _ActivitiesMapState extends State<ActivitiesMap> {
  GoogleMapController? _controller;
  String? _selectedId;
  double _cardHeight = 0;
  double _reportedOverlay = 0;

  double get _overlayHeight =>
      _selectedId == null ? 0 : _cardHeight + _cardMargin;

  void _reportOverlay() {
    final overlay = _overlayHeight;
    if (overlay == _reportedOverlay) return;
    _reportedOverlay = overlay;
    widget.onOverlayHeightChanged?.call(overlay);
  }

  void _onCardSize(Size size) {
    if (!mounted) return;
    if (size.height != _cardHeight) {
      setState(() => _cardHeight = size.height);
    }
    // S'avisa encara que l'alçada sigui la d'abans: si la targeta s'havia
    // tancat, els botons han de tornar a pujar.
    _reportOverlay();
  }

  @override
  void didUpdateWidget(covariant ActivitiesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedId != null &&
        !widget.activities.any(
          (activity) => activity.id == _selectedId && activity.location != null,
        )) {
      _selectedId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reportOverlay();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _select(Activity activity) {
    setState(() => _selectedId = activity.id);
    // Amb l'alçada coneguda els botons ja comencen a pujar; si la targeta nova
    // fa una altra mida, _onCardSize ho corregeix.
    if (_cardHeight > 0) _reportOverlay();
    final location = activity.location;
    if (location != null) {
      _controller?.animateCamera(CameraUpdate.newLatLng(_toLatLng(location)));
    }
  }

  void _clearSelection() {
    if (_selectedId == null) return;
    setState(() => _selectedId = null);
    _reportOverlay();
  }

  Future<void> _reportVisibleArea() async {
    final controller = _controller;
    if (widget.onVisibleAreaChanged == null || controller == null) return;
    final region = await controller.getVisibleRegion();
    // Abans que el mapa tingui mida, la zona visible és un sol punt.
    if (!mounted || region.southwest == region.northeast) return;
    widget.onVisibleAreaChanged?.call(
      GeoBounds(
        southWest: _toGeoPoint(region.southwest),
        northEast: _toGeoPoint(region.northeast),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final located = [
      for (final activity in widget.activities)
        if (activity.location != null) activity,
    ];
    final withoutLocation = widget.activities.length - located.length;
    final selected = located.where((a) => a.id == _selectedId).firstOrNull;
    final overlay = selected == null ? 0.0 : _cardHeight + _cardMargin;

    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            label: 'Mapa d’activitats',
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _toLatLng(cataloniaCenter),
                zoom: _initialZoom,
              ),
              onMapCreated: (controller) {
                _controller = controller;
                _reportVisibleArea();
              },
              onCameraIdle: _reportVisibleArea,
              onTap: (_) => _clearSelection(),
              clusterManagers: {
                const ClusterManager(clusterManagerId: _clusterManagerId),
              },
              markers: {
                for (final activity in located)
                  Marker(
                    markerId: MarkerId(activity.id),
                    position: _toLatLng(activity.location!),
                    clusterManagerId: _clusterManagerId,
                    consumeTapEvents: true,
                    icon: AssetMapBitmap(
                      activityMarkerAssets[activityMarkerKind(activity)]!,
                      width: 36,
                    ),
                    onTap: () => _select(activity),
                  ),
              },
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              // A la web, Google posa el control de càmera (fletxes i +/−) a
              // baix a la dreta, sota «Crear activitat»: el pugem a dalt.
              webCameraControlPosition: WebCameraControlPosition.rightTop,
            ),
          ),
        ),
        // La llegenda puja suaument per sobre de la targeta quan n'hi ha.
        AnimatedPositioned(
          duration: mapOverlayAnimationDuration,
          curve: _overlayCurve,
          left: 12,
          bottom: overlay == 0 ? 24 : overlay + _cardMargin,
          child: _LegendChip(withoutLocation: withoutLocation),
        ),
        Positioned(
          left: _cardMargin,
          right: _cardMargin,
          bottom: _cardMargin,
          // La targeta entra i surt des de baix.
          child: AnimatedSwitcher(
            duration: mapOverlayAnimationDuration,
            switchInCurve: _overlayCurve,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: selected == null
                ? const SizedBox.shrink()
                : _SizeReporter(
                    key: ValueKey(selected.id),
                    onChanged: _onCardSize,
                    child: _MapActivityCard(
                      activity: selected,
                      onClose: _clearSelection,
                      onOpen: () => widget.onActivitySelected(selected.id),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  static LatLng _toLatLng(GeoPoint point) =>
      LatLng(point.latitude, point.longitude);

  static GeoPoint _toGeoPoint(LatLng point) =>
      GeoPoint(latitude: point.latitude, longitude: point.longitude);
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.withoutLocation});

  final int withoutLocation;

  void _show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _LegendSheet(withoutLocation: withoutLocation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ActionChip(
      onPressed: () => _show(context),
      avatar: Icon(Icons.info_outline, size: 18, color: colors.primary),
      label: const Text('Llegenda'),
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.outlineVariant),
      shape: const StadiumBorder(),
    );
  }
}

class _LegendSheet extends StatelessWidget {
  const _LegendSheet({required this.withoutLocation});

  final int withoutLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget row(ActivityMarkerKind kind, String label) => ListTile(
      leading: Image.asset(activityMarkerAssets[kind]!, width: 28),
      title: Text(label),
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Llegenda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          row(ActivityMarkerKind.official, 'Activitat de l’Agenda Cultural'),
          row(ActivityMarkerKind.community, 'Publicada per un usuari'),
          row(ActivityMarkerKind.friend, 'Publicada per una amistat'),
          ListTile(
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Text('3', style: TextStyle(fontSize: 12)),
            ),
            title: const Text('Diverses activitats a prop: amplia el mapa'),
          ),
          if (withoutLocation > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                withoutLocation == 1
                    ? '1 activitat no té ubicació i només surt a la llista.'
                    : '$withoutLocation activitats no tenen ubicació i només '
                          'surten a la llista.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Targeta inferior del marcador seleccionat (fig. 7).
class _MapActivityCard extends StatelessWidget {
  const _MapActivityCard({
    required this.activity,
    required this.onClose,
    required this.onOpen,
  });

  final Activity activity;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final creator = activity.creator;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    activity.imageAsset,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: colors.surfaceContainerHighest,
                      child: const SizedBox.square(
                        dimension: 88,
                        child: Icon(Icons.image_outlined),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ActivityCategoryBadge(category: activity.category),
                      const SizedBox(height: 6),
                      Text(
                        activity.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ActivityInformationRow(
                        icon: Icons.location_on_outlined,
                        text: activity.municipality,
                      ),
                      const SizedBox(height: 4),
                      ActivityInformationRow(
                        icon: Icons.calendar_today_outlined,
                        text: formatActivitySchedule(activity.startsAt),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Tancar',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (creator != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Publicat per ${creator.name}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        if (creator.isFriend) ...[
                          const SizedBox(width: 6),
                          const FriendshipBadge(),
                        ],
                      ],
                    )
                  else
                    Text(
                      'Font: Agenda Cultural · Generalitat',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: onOpen,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right, size: 20),
                    label: const Text('Veure activitat'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avisa de la mida del fill després de cada canvi, per saber quant ocupa la
/// targeta (la seva alçada depèn del text i de la mida de la lletra).
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({super.key, required this.onChanged, super.child});

  final ValueChanged<Size> onChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) {
    renderObject.onChanged = onChanged;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onChanged);

  ValueChanged<Size> onChanged;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _lastSize) return;
    _lastSize = size;
    final reported = size;
    // No es pot canviar l'estat durant el layout: s'avisa després del frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(reported));
  }
}
