import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/user_position.dart';
import '../../repositories/user_location_repository.dart';

/// Resultat de prémer «La meva ubicació».
enum LocateResult {
  located,
  denied,
  deniedForever,
  serviceDisabled,
  unavailable,
}

/// On és la persona al mapa d'Inici.
///
/// El permís només es demana quan la persona prem el botó. Si ja el va donar,
/// en obrir el mapa es mostra on és sense preguntar res.
// TODO(DP-057): moment de demanar el permís sense mockup.
class UserLocationViewModel extends ChangeNotifier {
  UserLocationViewModel({
    required this._repository,
    this.locateTimeout = const Duration(seconds: 15),
  });

  final UserLocationRepository _repository;

  /// Temps màxim per trobar la posició després de prémer el botó.
  final Duration locateTimeout;

  UserPosition? _position;
  bool _isVisible = false;
  bool _isDisposed = false;
  StreamSubscription<UserPosition>? _subscription;
  final _positionWaiters = <Completer<UserPosition>>[];
  Future<LocateResult>? _locating;

  /// Última posició coneguda mentre el mapa és visible.
  UserPosition? get position => _position;
  bool get isLocating => _locating != null;
  bool get canOpenSettings => _repository.canOpenSettings;

  /// El mapa s'ha obert o l'app torna a primer pla (potser amb el permís
  /// donat des de la configuració): si hi ha permís, es mostra on és.
  Future<void> show() async {
    if (_isDisposed) return;
    _isVisible = true;
    try {
      if (await _repository.checkAccess() == LocationAccess.granted) {
        _listen();
      }
    } catch (_) {
      // Sense ubicació (p. ex. un navegador que no en té), el mapa va igual.
    }
  }

  /// El mapa ja no és visible: es deixa d'escoltar per no gastar bateria.
  void hide() {
    _isVisible = false;
    _stopListening();
    if (_position != null && !_isDisposed) {
      _position = null;
      notifyListeners();
    }
  }

  /// Demana el permís si cal i espera la posició, per centrar-hi el mapa.
  /// Mentre es busca, tornar a prémer el botó espera la mateixa cerca.
  Future<LocateResult> locate() {
    if (_locating case final locating?) return locating;
    final locating = _locate();
    _locating = locating;
    notifyListeners();
    return locating;
  }

  Future<LocateResult> _locate() async {
    try {
      final access = await _repository.requestAccess();
      switch (access) {
        case LocationAccess.granted:
          break;
        case LocationAccess.denied:
          return LocateResult.denied;
        case LocationAccess.deniedForever:
          return LocateResult.deniedForever;
        case LocationAccess.serviceDisabled:
          return LocateResult.serviceDisabled;
      }
      if (_isDisposed || !_isVisible) return LocateResult.unavailable;
      if (_position == null) {
        _listen();
        await _nextPosition().timeout(locateTimeout);
      }
      return LocateResult.located;
    } catch (_) {
      return LocateResult.unavailable;
    } finally {
      _locating = null;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> openAppSettings() => _repository.openAppSettings();

  Future<void> openLocationSettings() => _repository.openLocationSettings();

  void _listen() {
    if (_subscription != null || _isDisposed || !_isVisible) return;
    _subscription = _repository.watchPosition().listen(
      (position) {
        _position = position;
        for (final waiter in _positionWaiters) {
          waiter.complete(position);
        }
        _positionWaiters.clear();
        notifyListeners();
      },
      onError: (Object error) {
        _stopListening();
        for (final waiter in _positionWaiters) {
          waiter.completeError(error);
        }
        _positionWaiters.clear();
        if (_position != null) {
          _position = null;
          notifyListeners();
        }
      },
    );
  }

  Future<UserPosition> _nextPosition() {
    final waiter = Completer<UserPosition>();
    _positionWaiters.add(waiter);
    return waiter.future;
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopListening();
    super.dispose();
  }
}
