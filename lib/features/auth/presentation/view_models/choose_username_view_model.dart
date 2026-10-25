import 'package:flutter/foundation.dart';

import '../../models/auth_failure.dart';
import '../../repositories/auth_repository.dart';
import 'auth_failure_message.dart';
import 'auth_validators.dart';

class ChooseUsernameViewModel extends ChangeNotifier {
  ChooseUsernameViewModel({required this._repository});

  final AuthRepository _repository;

  bool _isLoading = false;
  bool _isDisposed = false;
  String? _usernameError;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get usernameError => _usernameError;
  String? get errorMessage => _errorMessage;

  /// L'usuari ha modificat el nom: en treu l'error i el missatge general.
  void onUsernameChanged() {
    if (_usernameError == null && _errorMessage == null) return;

    _usernameError = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Retorna `true` si s'ha desat el nom d'usuari. La pantalla no ha de
  /// navegar: el canvi arriba per `AuthRepository.authStateChanges`.
  Future<bool> submit(String username) async {
    if (_isLoading || _isDisposed) return false;

    _errorMessage = null;
    _usernameError = AuthValidators.username(username);

    if (_usernameError != null) {
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.chooseUsername(username.trim());
      return true;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } catch (_) {
      _errorMessage = unexpectedAuthErrorMessage;
      return false;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Sortida per a qui ha triat un compte de Google que no volia: sense
  /// sessió, `AuthGate` torna a mostrar el login.
  Future<void> signOut() async {
    if (_isLoading || _isDisposed) return;

    try {
      await _repository.signOut();
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = unexpectedAuthErrorMessage;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
