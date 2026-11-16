import 'package:flutter/foundation.dart';

import '../../models/activity.dart';
import '../../models/activity_filters.dart';
import '../../repositories/activity_repository.dart';

class ActivitiesViewModel extends ChangeNotifier {
  ActivitiesViewModel({required this._repository, this.pageSize = 50}) {
    if (pageSize < 1) throw RangeError.range(pageSize, 1, null, 'pageSize');
  }

  final ActivityRepository _repository;
  final int pageSize;

  List<Activity> _activities = const [];
  List<Activity> _catalogue = const [];
  ActivityFilters _filters = ActivityFilters();
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;
  bool _hasLoaded = false;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _nextPage = 0;
  int _generation = 0;
  String? _loadMoreError;
  List<String> _filterCategories = const [];
  bool _hasLoadedCategories = false;
  bool _isLoadingCategories = false;
  String? _categoriesError;

  List<Activity> get activities => _activities;
  ActivityFilters get filters => _filters;
  int get missingCategoryCount => _filters.missingCategoryCount(_catalogue);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoaded => _hasLoaded;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String? get loadMoreError => _loadMoreError;
  int get loadedCount => _catalogue.length;
  List<String> get filterCategories => _filterCategories;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoriesError => _categoriesError;

  Future<void> applyFilters(ActivityFilters filters) async {
    if (_isDisposed || filters == _filters) return;
    _filters = filters;
    // A new query owns its own pages. Never show the previous query's cards
    // under the new filter labels, even while loading or after an error.
    _activities = const [];
    _catalogue = const [];
    _hasLoaded = false;
    _hasMore = false;
    _nextPage = 0;
    _isLoading = false;
    await load();
  }

  Future<void> clearFilters() => applyFilters(ActivityFilters());

  Future<void> loadFilterCategories() async {
    if (_isDisposed || _isLoadingCategories || _hasLoadedCategories) return;
    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();
    try {
      final categories = await _repository.getFilterCategories();
      if (_isDisposed) return;
      _filterCategories = List.unmodifiable(categories);
      _hasLoadedCategories = categories.isNotEmpty;
    } catch (_) {
      if (_isDisposed) return;
      _categoriesError = 'No hem pogut carregar les categories.';
    } finally {
      if (!_isDisposed) {
        _isLoadingCategories = false;
        notifyListeners();
      }
    }
  }

  Future<void> load() async {
    if (_isLoading || _isDisposed) return;

    final generation = ++_generation;
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _loadMoreError = null;
    notifyListeners();

    try {
      final result = await _repository.getActivitiesPage(
        pageSize: pageSize,
        filters: _filters,
      );
      if (_isDisposed || generation != _generation) return;
      _catalogue = _merge(const [], result.items);
      _activities = _filters.applyTo(_catalogue);
      _nextPage = 1;
      _hasMore = result.hasMore;
      _hasLoaded = true;
    } catch (_) {
      if (_isDisposed || generation != _generation) return;

      _errorMessage =
          'No hem pogut carregar les activitats. Torna-ho a provar.';
    } finally {
      if (!_isDisposed && generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isDisposed ||
        !_hasLoaded ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMore) {
      return;
    }
    final generation = _generation;
    final page = _nextPage;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();
    try {
      final result = await _repository.getActivitiesPage(
        page: page,
        pageSize: pageSize,
        filters: _filters,
      );
      if (_isDisposed || generation != _generation) return;
      final merged = _merge(_catalogue, result.items);
      // Different category streams may legitimately overlap across batches.
      // Progress is the requested page, not the count of new unique IDs.
      _catalogue = merged;
      _activities = _filters.applyTo(_catalogue);
      _hasMore = result.hasMore;
      _nextPage = page + 1;
    } catch (_) {
      if (_isDisposed || generation != _generation) return;
      _loadMoreError =
          'No hem pogut carregar més activitats. Torna-ho a provar.';
    } finally {
      if (!_isDisposed && generation == _generation) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  List<Activity> _merge(Iterable<Activity> previous, Iterable<Activity> next) =>
      List.unmodifiable(
        {
          for (final activity in previous) activity.id: activity,
          for (final activity in next) activity.id: activity,
        }.values,
      );

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

//gestiona tres cosas: los eventos cargados, si estamos esperando y si ha ocurrido un error.
//El constructor recibe un ActivityRepository y lo guarda en _repository. Esto es inyección de dependencias: desde fuera decidimos qué repositorio utilizar. El ViewModel funciona con el de demostración y podrá funcionar con el del backend.
//el ViewModel sabe cargar actividades, pero no sabe dibujar tarjetas, navegar ni consultar directamente una API. Cada parte mantiene su responsabilidad.

/*
Pantalla → ViewModel.load()
                ↓
        ActivityRepository.getActivities()
        ejecutado por ApiActivityRepository
                ↓
           API del backend
                ↓
          Respuesta JSON
                ↓
   El repositorio convierte el JSON
          en List<Activity>
                ↓
            ViewModel
                ↓ notifyListeners()
   La pantalla se reconstruye con los datos
*/

//coordinador del estado y las acciones de esta pantalla

/*

| Elemento | Responsabilidad |

| Repositorio | Obtener y transformar los datos. |
| ViewModel | Coordinar la carga y mantener datos, carga y errores. |
| Pantalla y widgets | Mostrar ese estado y recibir las pulsaciones del usuario. |



*/
