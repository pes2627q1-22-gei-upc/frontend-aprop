import 'package:flutter/foundation.dart';

import '../../models/activity.dart';
import '../../models/geo_bounds.dart';
import '../../repositories/activity_map_repository.dart';

/// Activitats del mapa d'Inici per zona visible (CA3 de la #21).
class ActivitiesMapViewModel extends ChangeNotifier {
  ActivitiesMapViewModel({required this._repository});

  /// Marge que es carrega al voltant de la zona visible, perquè moure una mica
  /// el mapa no torni a demanar res.
  static const areaMargin = 0.5;

  final ActivityMapRepository _repository;

  List<Activity> _activities = const [];
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  /// Zona de la qual hi ha activitats carregades.
  GeoBounds? _loadedArea;

  /// Última zona visible, per tornar-ho a provar.
  GeoBounds? _visibleArea;

  /// Només s'aplica la resposta de l'última petició.
  int _lastRequest = 0;

  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasLoaded => _loadedArea != null;

  /// Carrega les activitats de [visibleArea] si encara no hi són. Mentre es
  /// carrega, es continuen mostrant les de la zona anterior.
  Future<void> loadArea(GeoBounds visibleArea) async {
    if (_isDisposed) return;
    _visibleArea = visibleArea;
    if (_loadedArea?.contains(visibleArea) ?? false) return;

    final request = ++_lastRequest;
    final area = visibleArea.expandedBy(areaMargin);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getActivitiesInArea(area);
      if (_isDisposed || request != _lastRequest) return;
      _activities = List.unmodifiable(result);
      _loadedArea = area;
    } catch (_) {
      if (_isDisposed || request != _lastRequest) return;
      _errorMessage =
          'No hem pogut carregar les activitats d’aquesta zona. '
          'Torna-ho a provar.';
    } finally {
      if (!_isDisposed && request == _lastRequest) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() async {
    final area = _visibleArea;
    if (area != null) await loadArea(area);
  }

  /// Torna a demanar la zona visible encara que ja hi fos, per exemple després
  /// de publicar-hi una activitat.
  Future<void> refresh() async {
    _loadedArea = null;
    await retry();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
