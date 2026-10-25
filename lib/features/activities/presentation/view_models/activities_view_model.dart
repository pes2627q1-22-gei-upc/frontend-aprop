import 'package:flutter/foundation.dart';

import '../../models/activity.dart';
import '../../models/activity_filters.dart';
import '../../repositories/activity_repository.dart';

class ActivitiesViewModel extends ChangeNotifier {
  ActivitiesViewModel({required this._repository});

  final ActivityRepository _repository;

  List<Activity> _activities = const [];
  List<Activity> _catalogue = const [];
  ActivityFilters _filters = ActivityFilters();
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  List<Activity> get activities => _activities;
  ActivityFilters get filters => _filters;
  int get missingCategoryCount => _filters.missingCategoryCount(_catalogue);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void applyFilters(ActivityFilters filters) {
    if (_isDisposed || filters == _filters) return;
    _filters = filters;
    _activities = filters.applyTo(_catalogue);
    notifyListeners();
  }

  void clearFilters() => applyFilters(ActivityFilters());

  Future<void> load() async {
    //activa la carga, borra el error anterior y avisa a sus posibles oyentes
    if (_isLoading || _isDisposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getActivities();

      if (_isDisposed) return;

      _catalogue = List.unmodifiable(result);
      _activities = _filters.applyTo(_catalogue);
    } catch (_) {
      if (_isDisposed) return;

      _errorMessage =
          'No hem pogut carregar les activitats. Torna-ho a provar.';
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

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
