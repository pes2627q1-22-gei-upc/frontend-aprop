import 'package:flutter/material.dart';

import '../../models/activity_filters.dart';
import '../formatters/activity_filter_formatter.dart';
import '../view_models/activities_map_view_model.dart';
import '../view_models/activities_view_model.dart';
import '../view_models/enrollment_view_model.dart';
import '../widgets/activities_header.dart';
import '../widgets/activities_map.dart';
import '../widgets/activity_card.dart';
import '../widgets/activity_categories_filter_sheet.dart';
import '../widgets/activity_date_filter_sheet.dart';
import '../widgets/activity_filter_feedback.dart';
import '../widgets/activity_list_pagination.dart';
import '../widgets/enrollment_action.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({
    super.key,
    required this.viewModel,
    required this.enrollmentViewModel,
    required this.onActivitySelected,
    this.onAssistantPressed,
    this.onMapOverlayChanged,
    this.mapViewModel,
    this.onMapActivitySelected,
    this.now = DateTime.now,
  });

  final ActivitiesViewModel viewModel;
  final EnrollmentViewModel enrollmentViewModel;
  final ValueChanged<String> onActivitySelected;
  final VoidCallback? onAssistantPressed;
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
  // La llista és la vista inicial: si Google Maps falla (p. ex. sense clau), Inici continua
  // funcionant (CA3 de la #21).
  // TODO(DP-022): el mockup (fig. 7) obre Inici amb el mapa.
  ActivitiesView _view = ActivitiesView.list;
  late final _listController = ScrollController(onAttach: _onListAttached);
  bool _resetListOnAttach = false;
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
      barrierLabel: 'Tancar el filtre',
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
    _resetListOnAttach = true;
    viewModel.applyFilters(filters);
    if (_listController.hasClients) {
      _listController.jumpTo(0);
      _resetListOnAttach = false;
    }
  }

  void _onListAttached(ScrollPosition position) {
    if (!_resetListOnAttach) return;
    // The list may have been unmounted while filters changed on the map.
    // Wait for layout before replacing its stored scroll position.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _resetListOnAttach &&
          _listController.positions.contains(position)) {
        position.jumpTo(0);
        _resetListOnAttach = false;
      }
    });
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

  String? get _filterSummary {
    final filters = viewModel.filters;
    if (!filters.isActive) return null;
    return [
      if (filters.dates != null)
        formatFilterDateRange(filters.dates, year: widget.now().year),
      if (filters.categories.isNotEmpty)
        formatCategorySelection(filters.categories),
    ].join(' · ');
  }

  ActivitiesViewModel get viewModel => widget.viewModel;
  EnrollmentViewModel get enrollmentViewModel => widget.enrollmentViewModel;
  ValueChanged<String> get onActivitySelected => widget.onActivitySelected;

  void _show(ActivitiesView view) {
    if (view == _view) return;
    setState(() => _view = view);
    // A la llista no hi ha targeta del mapa: el botó torna a baix.
    if (view == ActivitiesView.list) widget.onMapOverlayChanged?.call(0);
  }

  @override
  Widget build(BuildContext context) {
    final header = ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) => ActivitiesHeader(
        selectedView: _view,
        onAssistantPressed: widget.onAssistantPressed,
        onMapPressed: () => _show(ActivitiesView.map),
        onListPressed: () => _show(ActivitiesView.list),
        onDatesPressed: _openDates,
        onCategoriesPressed: _openCategories,
        datesSelected: viewModel.filters.dates != null,
        categoriesSelected: viewModel.filters.categories.isNotEmpty,
        filterSummary: _filterSummary,
        onClearFilters: _clearFilters,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
        return Column(
          children: [
            if (largeText || constraints.maxHeight < 600)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * .6,
                ),
                child: SingleChildScrollView(
                  key: const ValueKey('activities-header-scroll'),
                  child: header,
                ),
              )
            else
              header,
            Expanded(child: _buildContent()),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    final mapViewModel = widget.mapViewModel;
    if (_view == ActivitiesView.map && mapViewModel != null) {
      return _buildAreaMap(mapViewModel);
    }

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
                    child: const Text('Tornar-ho a provar'),
                  ),
                ],
              ),
            ),
          );
        }

        final activities = viewModel.activities;

        if (_view == ActivitiesView.map) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ActivitiesMap(
                    activities: activities,
                    onActivitySelected: onActivitySelected,
                    onOverlayHeightChanged: widget.onMapOverlayChanged,
                    interactive: _activeFilterRoute == null,
                  ),
                ),
                if (viewModel.filters.isActive &&
                    (activities.isEmpty || viewModel.missingCategoryCount > 0))
                  Positioned.fill(
                    child: MapFilterFeedback(
                      isEmpty: activities.isEmpty,
                      missingCategories: viewModel.missingCategoryCount,
                      onClear: _clearFilters,
                    ),
                  ),
              ],
            ),
          );
        }

        final contentCount = activities.isEmpty ? 1 : activities.length;
        final showPagination = viewModel.hasMore;
        final notices = <Widget>[
          if (errorMessage != null)
            Column(
              children: [
                Semantics(liveRegion: true, child: Text(errorMessage)),
                TextButton(
                  onPressed: viewModel.load,
                  child: const Text('Tornar-ho a provar'),
                ),
              ],
            ),
          if (viewModel.missingCategoryCount > 0 && activities.isNotEmpty)
            MissingCategoryNotice(count: viewModel.missingCategoryCount),
        ];
        return Column(
          children: [
            if (viewModel.isLoading)
              const LinearProgressIndicator(
                semanticsLabel: 'Actualitzant les activitats',
              ),
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
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'No hi ha activitats disponibles.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final activity = activities[contentIndex];

                    return ActivityCard(
                      key: ValueKey(activity.id),
                      activity: activity,
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
  Widget _buildAreaMap(ActivitiesMapViewModel mapViewModel) {
    return ListenableBuilder(
      listenable: Listenable.merge([mapViewModel, viewModel]),
      builder: (context, child) {
        final errorMessage = mapViewModel.errorMessage;
        final filters = viewModel.filters;
        final activities = filters.applyTo(mapViewModel.activities);
        final missingCategories = filters.missingCategoryCount(
          mapViewModel.activities,
        );

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Stack(
            children: [
              Positioned.fill(
                child: ActivitiesMap(
                  activities: activities,
                  onActivitySelected:
                      widget.onMapActivitySelected ?? onActivitySelected,
                  onOverlayHeightChanged: widget.onMapOverlayChanged,
                  interactive: _activeFilterRoute == null,
                  onVisibleAreaChanged: mapViewModel.loadArea,
                ),
              ),
              if (mapViewModel.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    semanticsLabel: 'Carregant les activitats de la zona',
                  ),
                ),
              if (errorMessage != null)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _MapErrorBanner(
                    message: errorMessage,
                    onRetry: mapViewModel.retry,
                  ),
                ),
              if (!mapViewModel.isLoading &&
                  errorMessage == null &&
                  ((filters.isActive &&
                          activities.isEmpty &&
                          mapViewModel.hasLoaded) ||
                      missingCategories > 0))
                Positioned.fill(
                  child: MapFilterFeedback(
                    isEmpty: activities.isEmpty,
                    missingCategories: missingCategories,
                    onClear: _clearFilters,
                    onShowList: () => _show(ActivitiesView.list),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MapErrorBanner extends StatelessWidget {
  const _MapErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
            TextButton(
              onPressed: onRetry,
              child: const Text('Tornar-ho a provar'),
            ),
          ],
        ),
      ),
    );
  }
}
