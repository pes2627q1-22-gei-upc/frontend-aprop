import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity.dart';
import '../../models/activity_filters.dart';
import '../formatters/activity_filter_formatter.dart';
import '../view_models/activities_map_view_model.dart';
import '../view_models/activities_view_model.dart';
import '../view_models/enrollment_view_model.dart';
import '../view_models/user_location_view_model.dart';
import '../widgets/activities_map.dart';
import '../widgets/activity_card.dart';
import '../widgets/activity_categories_filter_sheet.dart';
import '../widgets/activity_date_filter_sheet.dart';
import '../widgets/activity_filter_feedback.dart';
import '../widgets/activity_list_pagination.dart';
import '../widgets/enrollment_action.dart';
import '../widgets/google_maps_availability.dart';
import '../widgets/map_filter_bar.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({
    super.key,
    required this.viewModel,
    required this.enrollmentViewModel,
    required this.onActivitySelected,
    this.onSearchPressed,
    this.onMapOverlayChanged,
    this.mapViewModel,
    this.onMapActivitySelected,
    this.userLocationViewModel,
    this.googleMapsAvailable,
    this.now = DateTime.now,
  });

  /// On és la persona. Sense, el mapa no mostra ni el punt ni el botó.
  final UserLocationViewModel? userLocationViewModel;

  final ActivitiesViewModel viewModel;
  final EnrollmentViewModel enrollmentViewModel;
  final ValueChanged<String> onActivitySelected;

  /// Obre la cerca des de la barra de dalt del mapa.
  final VoidCallback? onSearchPressed;

  /// Si Google Maps es pot dibuixar. Per defecte es comprova (a la web cal
  /// que s'hagi carregat el script); les proves el poden fixar.
  final bool? googleMapsAvailable;
  final DateTime Function() now;

  /// Si hi és, el mapa carrega les activitats per zona visible (backend) en
  /// lloc de mostrar les de la llista.
  // TODO(DP-029): mapa i llista haurien de tenir el mateix conjunt d'activitats.
  final ActivitiesMapViewModel? mapViewModel;

  /// Obre una activitat del mapa quan ve d'una altra font que la llista. Per
  /// defecte, [onActivitySelected].
  final ValueChanged<String>? onMapActivitySelected;

  /// Espai que ocupa la targeta del mapa des de baix (0 si no n'hi ha), per
  /// apartar-hi el botó «Crear activitat».
  final ValueChanged<double>? onMapOverlayChanged;

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  // Només hi ha mapa (#274). Si Google Maps no es pot dibuixar, en el seu
  // lloc surt la llista, perquè l'app no quedi bloquejada (CA3 de la #21).
  final _listController = ScrollController();
  Route<dynamic>? _activeFilterRoute;

  @override
  void didUpdateWidget(covariant ActivitiesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) _closeFilter();
  }

  @override
  void dispose() {
    _closeFilter();
    _listController.dispose();
    super.dispose();
  }

  void _closeFilter() {
    final route = _activeFilterRoute;
    _activeFilterRoute = null;
    if (route == null) return;
    // A root modal covers the bottom navigation. Remove only our own route
    // after the current frame if its account/screen disappears underneath it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route.isActive) route.navigator?.removeRoute(route);
    });
  }

  Future<T?> _showFilter<T>(String name, WidgetBuilder builder) async {
    if (_activeFilterRoute != null) return null;
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = ModalBottomSheetRoute<T>(
      settings: RouteSettings(name: '/activities/filters/$name'),
      builder: builder,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      barrierLabel: context.l10n.actCloseFilter,
    );
    // Mentre el panell és obert, el mapa de sota no respon (#255).
    setState(() => _activeFilterRoute = route);
    try {
      return await navigator.push<T>(route);
    } finally {
      if (identical(_activeFilterRoute, route) && mounted) {
        setState(() => _activeFilterRoute = null);
      }
    }
  }

  void _applyFilters(ActivityFilters filters) {
    if (filters == viewModel.filters) return;
    viewModel.applyFilters(filters);
    // La llista de reserva sempre està muntada (no hi ha selector de vista):
    // un filtre nou la torna a dalt.
    if (_listController.hasClients) _listController.jumpTo(0);
  }

  void _clearFilters() => _applyFilters(ActivityFilters());

  Future<void> _openDates() async {
    final owner = viewModel;
    final initial = owner.filters.dates;
    final today = widget.now();
    final result = await _showFilter<ActivityDateSelection>(
      'dates',
      (_) => ActivityDateFilterSheet(today: today, initialDates: initial),
    );
    if (mounted && identical(owner, viewModel) && result != null) {
      _applyFilters(owner.filters.withDates(result.dates));
    }
  }

  Future<void> _openCategories() async {
    final owner = viewModel;
    final initial = owner.filters.categories;
    owner.loadFilterCategories();
    final result = await _showFilter<Set<String>>(
      'categories',
      (_) => ListenableBuilder(
        listenable: owner,
        builder: (context, _) => ActivityCategoriesFilterSheet(
          initialCategories: initial,
          categories: owner.filterCategories,
          isLoading: owner.isLoadingCategories,
          errorMessage: owner.categoriesError,
          onRetry: owner.loadFilterCategories,
        ),
      ),
    );
    if (mounted && identical(owner, viewModel) && result != null) {
      _applyFilters(owner.filters.withCategories(result));
    }
  }

  ActivitiesViewModel get viewModel => widget.viewModel;
  EnrollmentViewModel get enrollmentViewModel => widget.enrollmentViewModel;

  /// «Apuntat» i el botó per apuntar-se a la targeta del marcador del mapa.
  Widget _mapEnrollmentAction(Activity activity) => EnrollmentAction(
    viewModel: enrollmentViewModel,
    activityId: activity.id,
    activityTitle: activity.title,
  );
  ValueChanged<String> get onActivitySelected => widget.onActivitySelected;

  @override
  Widget build(BuildContext context) {
    final bar = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final filters = viewModel.filters;
          return MapFilterBar(
            onSearchPressed: widget.onSearchPressed,
            onDatesPressed: _openDates,
            onCategoriesPressed: _openCategories,
            onClearFilters: filters.isActive ? _clearFilters : null,
            datesLabel: filters.dates == null
                ? null
                : formatFilterDateRange(filters.dates, year: widget.now().year),
            categoriesLabel: filters.categories.isEmpty
                ? null
                : formatCategorySelection(filters.categories),
          );
        },
      ),
    );
    if (!(widget.googleMapsAvailable ?? isGoogleMapsAvailable)) {
      return Column(
        children: [
          bar,
          Expanded(child: _buildList()),
        ],
      );
    }
    final mapViewModel = widget.mapViewModel;
    return mapViewModel == null
        ? _buildCatalogueMap(bar)
        : _buildAreaMap(mapViewModel, bar);
  }

  /// El mapa a tota la pantalla i, a sobre, la barra de filtres i els avisos.
  /// Els espais buits de la capa de sobre deixen passar els tocs al mapa.
  Widget _mapWithOverlay({
    required Widget map,
    required Widget bar,
    bool isLoading = false,
    String? loadingLabel,
    String? errorMessage,
    VoidCallback? onRetry,
    Widget? feedback,
  }) {
    return Stack(
      children: [
        Positioned.fill(child: map),
        Positioned.fill(
          child: Column(
            children: [
              bar,
              Expanded(
                child: Stack(
                  children: [
                    if (isLoading)
                      Positioned(
                        top: 0,
                        left: 12,
                        right: 12,
                        child: LinearProgressIndicator(
                          semanticsLabel: loadingLabel,
                        ),
                      ),
                    if (errorMessage != null)
                      Positioned(
                        top: 8,
                        left: 12,
                        right: 12,
                        child: _MapErrorBanner(
                          message: errorMessage,
                          onRetry: onRetry,
                        ),
                      ),
                    ?feedback,
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mapa amb les activitats del catàleg (sense mapa del backend).
  Widget _buildCatalogueMap(Widget bar) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final activities = viewModel.activities;
        return _mapWithOverlay(
          bar: bar,
          map: ActivitiesMap(
            activities: activities,
            preferredCategories: viewModel.filters.categories,
            onActivitySelected: onActivitySelected,
            onOverlayHeightChanged: widget.onMapOverlayChanged,
            interactive: _activeFilterRoute == null,
            participationActionBuilder: _mapEnrollmentAction,
            userLocation: widget.userLocationViewModel,
          ),
          isLoading: viewModel.isLoading,
          loadingLabel: context.l10n.actUpdating,
          errorMessage: viewModel.hasLoaded ? null : viewModel.errorMessage,
          onRetry: viewModel.load,
          feedback:
              viewModel.filters.isActive &&
                  viewModel.hasLoaded &&
                  (activities.isEmpty || viewModel.missingCategoryCount > 0)
              ? Positioned.fill(
                  child: MapFilterFeedback(
                    isEmpty: activities.isEmpty,
                    missingCategories: viewModel.missingCategoryCount,
                    onClear: _clearFilters,
                  ),
                )
              : null,
        );
      },
    );
  }

  /// La llista, només si Google Maps no es pot dibuixar.
  Widget _buildList() {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        if (viewModel.isLoading && !viewModel.hasLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final errorMessage = viewModel.errorMessage;

        if (errorMessage != null && !viewModel.hasLoaded) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: viewModel.load,
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final activities = viewModel.activities;

        final contentCount = activities.isEmpty ? 1 : activities.length;
        final showPagination = viewModel.hasMore;
        final notices = <Widget>[
          if (errorMessage != null)
            Column(
              children: [
                Semantics(liveRegion: true, child: Text(errorMessage)),
                TextButton(
                  onPressed: viewModel.load,
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          if (viewModel.missingCategoryCount > 0 && activities.isNotEmpty)
            MissingCategoryNotice(count: viewModel.missingCategoryCount),
        ];
        return Column(
          children: [
            if (viewModel.isLoading)
              LinearProgressIndicator(semanticsLabel: context.l10n.actUpdating),
            Expanded(
              child: RefreshIndicator(
                onRefresh: viewModel.load,
                child: ListView.separated(
                  key: const PageStorageKey<String>('activities-list'),
                  controller: _listController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Marge inferior perquè el botó «Crear activitat» no tapi l'última
                  // targeta.
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount:
                      notices.length + contentCount + (showPagination ? 1 : 0),
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    if (index < notices.length) return notices[index];
                    final contentIndex = index - notices.length;
                    if (contentIndex == contentCount) {
                      return ActivityListPagination(
                        loadedCount: viewModel.loadedCount,
                        isLoading:
                            viewModel.isLoadingMore || viewModel.isLoading,
                        errorMessage: viewModel.loadMoreError,
                        onLoadMore: viewModel.loadMore,
                      );
                    }
                    if (activities.isEmpty) {
                      if (viewModel.filters.isActive) {
                        return FilteredActivitiesEmptyState(
                          onClear: _clearFilters,
                          missingCategories: viewModel.missingCategoryCount,
                          isPartialCatalogue: viewModel.hasMore,
                          scrollable: false,
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          context.l10n.actNoneAvailable,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final activity = activities[contentIndex];

                    return ActivityCard(
                      key: ValueKey(activity.id),
                      activity: activity,
                      preferredCategories: viewModel.filters.categories,
                      onTap: () => onActivitySelected(activity.id),
                      participationAction: EnrollmentAction(
                        viewModel: enrollmentViewModel,
                        activityId: activity.id,
                        activityTitle: activity.title,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Mapa que carrega la zona visible. Mentre carrega o si falla, continua
  /// mostrant les activitats que ja tenia.
  Widget _buildAreaMap(ActivitiesMapViewModel mapViewModel, Widget bar) {
    return ListenableBuilder(
      listenable: Listenable.merge([mapViewModel, viewModel]),
      builder: (context, child) {
        final errorMessage = mapViewModel.errorMessage;
        final filters = viewModel.filters;
        final activities = filters.applyTo(mapViewModel.activities);
        final missingCategories = filters.missingCategoryCount(
          mapViewModel.activities,
        );

        return _mapWithOverlay(
          bar: bar,
          map: ActivitiesMap(
            activities: activities,
            preferredCategories: filters.categories,
            onActivitySelected:
                widget.onMapActivitySelected ?? onActivitySelected,
            onOverlayHeightChanged: widget.onMapOverlayChanged,
            interactive: _activeFilterRoute == null,
            onVisibleAreaChanged: mapViewModel.loadArea,
            participationActionBuilder: _mapEnrollmentAction,
            userLocation: widget.userLocationViewModel,
          ),
          isLoading: mapViewModel.isLoading,
          loadingLabel: context.l10n.actLoadingZone,
          errorMessage: errorMessage,
          onRetry: mapViewModel.retry,
          feedback:
              !mapViewModel.isLoading &&
                  errorMessage == null &&
                  ((filters.isActive &&
                          activities.isEmpty &&
                          mapViewModel.hasLoaded) ||
                      missingCategories > 0)
              ? Positioned.fill(
                  child: MapFilterFeedback(
                    isEmpty: activities.isEmpty,
                    missingCategories: missingCategories,
                    onClear: _clearFilters,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _MapErrorBanner extends StatelessWidget {
  const _MapErrorBanner({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            const SizedBox(width: 8),
            TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
