import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/activity.dart';
import '../../models/geo_bounds.dart';
import '../../models/geo_point.dart';
import '../formatters/activity_date_formatter.dart';
import 'activity_badges.dart';
import 'activity_information_row.dart';
import 'activity_image.dart';
import 'activity_map_groups.dart';
import 'map_group_icon.dart';

/// Durada de les transicions de la targeta i dels botons que s'hi aparten.
const mapOverlayAnimationDuration = Duration(milliseconds: 280);
const _overlayCurve = Curves.easeOutCubic;
const _cardMargin = 12.0;
const _initialZoom = 7.0;

/// Marge, en píxels lògics, que queda al voltant d'un grup en apropar-s'hi.
const _clusterPadding = 64.0;

/// Temps durant el qual un toc al mapa es considera el mateix clic que s'ha
/// fet sobre una cosa que el tapa (vegeu `_onMapTap`).
const _cardClickEcho = Duration(milliseconds: 500);

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
    this.interactive = true,
    this.participationActionBuilder,
  });

  final List<Activity> activities;
  final ValueChanged<String> onActivitySelected;

  /// Acció per apuntar-se des de la targeta del marcador. Qui conté el mapa
  /// decideix què hi va; sense, la targeta porta «Veure activitat».
  final Widget Function(Activity activity)? participationActionBuilder;

  /// Espai que ocupa la targeta del marcador des de baix (0 si no n'hi ha),
  /// perquè qui conté el mapa pugui apartar-hi els seus botons.
  final ValueChanged<double>? onOverlayHeightChanged;

  /// Zona visible en obrir el mapa i cada cop que s'acaba de moure, per
  /// carregar-ne les activitats.
  final ValueChanged<GeoBounds>? onVisibleAreaChanged;

  /// Fals mentre hi ha un panell a sobre del mapa (filtres de dates o
  /// categories). A la web, el mapa de Google és per sota de Flutter i, si
  /// no, continuaria rebent arrossegaments, la roda del ratolí i clics.
  final bool interactive;

  @override
  State<ActivitiesMap> createState() => _ActivitiesMapState();
}

class _ActivitiesMapState extends State<ActivitiesMap> {
  GoogleMapController? _controller;
  String? _selectedId;
  double _cardHeight = 0;
  double _reportedOverlay = 0;

  /// Zoom amb què s'agrupen els marcadors. Es posa al dia quan el mapa
  /// s'acaba de moure, no a cada pas, perquè els grups no parpellegin.
  double _zoom = _initialZoom;
  double _cameraZoom = _initialZoom;

  /// Cercles dels grups ja dibuixats. Es guarden pel text («5», «2019»...),
  /// els colors i la densitat de píxels: si canvia el tema o la pantalla, es
  /// tornen a dibuixar.
  final Map<_GroupIconKey, BitmapDescriptor> _groupIcons = {};
  final Set<_GroupIconKey> _drawingGroupIcons = {};

  /// Últims grups calculats, perquè obrir o tancar la targeta no els torni a
  /// calcular: amb milers d'activitats, és feina.
  List<ActivityMapGroup> _groups = const [];
  List<Activity>? _groupedActivities;
  double? _groupedZoom;

  List<ActivityMapGroup> _groupsFor(List<Activity> activities) {
    if (!identical(activities, _groupedActivities) || _groupedZoom != _zoom) {
      _groups = groupActivitiesForMap(activities, _zoom);
      _groupedActivities = activities;
      _groupedZoom = _zoom;
    }
    return _groups;
  }

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
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
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

  /// Panells que obre el mateix mapa (llegenda, activitats d'un mateix
  /// lloc) i que encara són oberts.
  int _openSheets = 0;

  /// El mapa només respon quan no té res a sobre.
  bool get _isInteractive => widget.interactive && _openSheets == 0;

  Future<void> _showSheet(WidgetBuilder builder, {bool tall = false}) async {
    setState(() => _openSheets++);
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: tall,
        builder: builder,
      );
    } finally {
      // A la web, el clic que tanca el panell també arriba al mapa: torna a
      // respondre al fotograma següent, quan aquest clic ja ha passat.
      WidgetsBinding.instance
        ..addPostFrameCallback((_) {
          if (mounted) setState(() => _openSheets--);
        })
        ..scheduleFrame();
    }
  }

  /// Últim clic acabat sobre alguna cosa de Flutter que tapa el mapa: la
  /// targeta, l'avís de «Desfer», un diàleg...
  DateTime? _overlayReleasedAt;

  /// A la web, el mapa de Google és per sota de Flutter i també rep els
  /// clics fets sobre el que hi ha a sobre: en prémer «M’hi apunto» o
  /// «Desfer», tancaria la targeta. Per això es mira cada clic que acaba
  /// dins del mapa: si el que hi ha a sobre no és el mapa, és d'una altra
  /// cosa.
  void _onPointer(PointerEvent event) {
    if (event is! PointerUpEvent || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final local = box.globalToLocal(event.position);
    if (!(Offset.zero & box.size).contains(local)) return;

    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
    if (result.path.firstOrNull?.target is! PlatformViewRenderBox) {
      _overlayReleasedAt = DateTime.now();
    }
  }

  /// El mapa respon a un toc (al mapa, a un marcador o a un grup) només si no
  /// té res a sobre i el toc no és el mateix clic fet just abans sobre una
  /// cosa que el tapa, com la targeta.
  // TODO(DP-045): treure-ho si es fa servir `pointer_interceptor`.
  bool get _acceptsTap {
    if (!_isInteractive) return false;
    final released = _overlayReleasedAt;
    return released == null ||
        DateTime.now().difference(released) >= _cardClickEcho;
  }

  void _onMapTap() {
    if (_acceptsTap) _clearSelection();
  }

  void _clearSelection() {
    if (_selectedId == null) return;
    setState(() => _selectedId = null);
    _reportOverlay();
  }

  /// Tocar un grup hi apropa el mapa fins que hi caben tots els marcadors, que
  /// així es van separant. Si són tots al mateix lloc, se'n mostra la llista.
  void _onGroupTap(ActivityMapGroup group) {
    if (!_acceptsTap) return;
    _clearSelection();
    final bounds = group.bounds;
    if (isSamePlace(bounds)) {
      _showSamePlace(List.of(group.activities));
      return;
    }
    _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: _toLatLng(bounds.southWest),
          northeast: _toLatLng(bounds.northEast),
        ),
        _clusterPadding,
      ),
    );
  }

  /// Les activitats d'un mateix lloc sempre van en grup: un marcador sol és
  /// una sola activitat.
  void _onMarkerTap(Activity activity) {
    if (_acceptsTap) _select(activity);
  }

  /// Cercle del grup amb el text [label]. Mentre es dibuixa, un marcador del
  /// color de l'app.
  BitmapDescriptor _groupIcon(String label, ColorScheme colors) {
    final key = (
      label: label,
      fill: colors.primary,
      textColor: colors.onPrimary,
      border: colors.surface,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    final icon = _groupIcons[key];
    if (icon != null) return icon;
    if (_drawingGroupIcons.add(key)) {
      drawMapGroupIcon(
        label,
        fill: key.fill,
        textColor: key.textColor,
        border: key.border,
        devicePixelRatio: key.devicePixelRatio,
      ).then(
        (drawn) {
          if (mounted) setState(() => _groupIcons[key] = drawn);
        },
        // Si no es pot dibuixar, es torna a provar en el proper redibuix.
        onError: (Object _) {
          _drawingGroupIcons.remove(key);
        },
      );
    }
    return BitmapDescriptor.defaultMarkerWithHue(
      HSVColor.fromColor(colors.primary).hue,
    );
  }

  void _showSamePlace(List<Activity> activities) {
    if (activities.isEmpty) return;
    activities.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    _showSheet(
      tall: true,
      (context) => _SamePlaceSheet(
        activities: activities,
        onSelected: (id) {
          Navigator.of(context).pop();
          widget.onActivitySelected(id);
        },
      ),
    );
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
    final groups = _groupsFor(widget.activities);
    final colors = Theme.of(context).colorScheme;
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
              onCameraMove: (position) => _cameraZoom = position.zoom,
              onCameraIdle: () {
                if (_cameraZoom != _zoom) {
                  setState(() => _zoom = _cameraZoom);
                }
                _reportVisibleArea();
              },
              onTap: (_) {
                _onMapTap();
              },
              // Amb un panell a sobre, el mapa no es mou: a la web, si no,
              // la roda i els arrossegaments hi arribarien igualment.
              scrollGesturesEnabled: _isInteractive,
              zoomGesturesEnabled: _isInteractive,
              rotateGesturesEnabled: _isInteractive,
              tiltGesturesEnabled: _isInteractive,
              // Els grups els fa l'app (activity_map_groups.dart) i no Google,
              // perquè siguin iguals a la web i al mòbil i amb els colors de
              // l'app.
              markers: {
                for (final group in groups)
                  if (group.isSingle)
                    Marker(
                      markerId: MarkerId(group.id),
                      position: _toLatLng(group.center),
                      consumeTapEvents: true,
                      icon: AssetMapBitmap(
                        activityMarkerAssets[activityMarkerKind(
                          group.activities.single,
                        )]!,
                        width: 36,
                      ),
                      onTap: () => _onMarkerTap(group.activities.single),
                    )
                  else
                    Marker(
                      markerId: MarkerId(group.id),
                      position: _toLatLng(group.center),
                      anchor: const Offset(0.5, 0.5),
                      // Per sobre dels marcadors sols que hi pugui haver a prop.
                      zIndexInt: 1,
                      consumeTapEvents: true,
                      icon: _groupIcon(
                        mapGroupLabel(group.activities.length),
                        colors,
                      ),
                      onTap: () => _onGroupTap(group),
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
          child: _LegendChip(
            onPressed: () => _showSheet(
              (context) => _LegendSheet(withoutLocation: withoutLocation),
            ),
          ),
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
                      participationAction: widget.participationActionBuilder
                          ?.call(selected),
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
  const _LegendChip({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ActionChip(
      onPressed: onPressed,
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
            title: const Text('Diverses activitats a prop: toca per veure-les'),
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

/// Activitats d'un grup que són totes al mateix lloc, per triar-ne una.
// TODO(DP-034): disseny sense mockup.
class _SamePlaceSheet extends StatelessWidget {
  const _SamePlaceSheet({required this.activities, required this.onSelected});

  final List<Activity> activities;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ConstrainedBox(
        // Amb moltes activitats, la llista es desplaça i deixa veure el mapa.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text(
                '${activities.length} activitats en aquest lloc',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (activities.first.municipality.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  activities.first.municipality,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return ListTile(
                    leading: Image.asset(
                      activityMarkerAssets[activityMarkerKind(activity)]!,
                      width: 28,
                      excludeFromSemantics: true,
                    ),
                    title: Text(activity.title),
                    subtitle: Text(
                      formatActivityWhen(activity, includeDate: true),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onSelected(activity.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Targeta inferior del marcador seleccionat (fig. 7). Tocar-la a qualsevol
/// lloc obre l'activitat.
class _MapActivityCard extends StatelessWidget {
  const _MapActivityCard({
    required this.activity,
    required this.onClose,
    required this.onOpen,
    this.participationAction,
  });

  final Activity activity;

  /// Per apuntar-s'hi des del mapa. Sense, la targeta porta «Veure activitat».
  final Widget? participationAction;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final creator = activity.creator;
    final source = creator != null
        ? Row(
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
        : Text(
            'Font: Agenda Cultural · Generalitat',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      // Els botons de dins (tancar, apuntar-s'hi) fan la seva acció. Per al
      // lector de pantalla, el títol és el botó per obrir-la.
      child: InkWell(
        onTap: onOpen,
        excludeFromSemantics: true,
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
                    child: ActivityImage(
                      activity: activity,
                      width: 88,
                      height: 88,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ActivityCategoriesSummary(
                          categories: activity.categories,
                        ),
                        InkWell(
                          onTap: onOpen,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    activity.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                          ),
                        ),
                        if (activity.municipality.isNotEmpty) ...[
                          ActivityInformationRow(
                            icon: Icons.location_on_outlined,
                            text: activity.municipality,
                          ),
                          const SizedBox(height: 4),
                        ],
                        ActivityInformationRow(
                          icon: Icons.calendar_today_outlined,
                          text: formatActivityWhen(activity),
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
                child: switch (participationAction) {
                  final action? => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [source, const SizedBox(height: 8), action],
                  ),
                  null => Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      source,
                      FilledButton.icon(
                        onPressed: onOpen,
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.chevron_right, size: 20),
                        label: const Text('Veure activitat'),
                      ),
                    ],
                  ),
                },
              ),
            ],
          ),
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

/// El que fa diferent el dibuix d'un grup.
typedef _GroupIconKey = ({
  String label,
  Color fill,
  Color textColor,
  Color border,
  double devicePixelRatio,
});
