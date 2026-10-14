import 'package:flutter/foundation.dart';

import '../../models/auth_failure.dart';
import '../../repositories/auth_repository.dart';
import 'auth_failure_message.dart';
import 'auth_validators.dart';

enum LoginField { usernameOrEmail, password }

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required this._repository});

  final AuthRepository _repository;

  final Map<LoginField, String> _fieldErrors = {};
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? fieldError(LoginField field) => _fieldErrors[field];

  /// L'usuari ha modificat un camp: en treu l'error i el missatge general.
  /// Es tornaran a comprovar quan torni a enviar el formulari.
  void onFieldChanged(LoginField field) {
    final hadFieldError = _fieldErrors.remove(field) != null;
    if (!hadFieldError && _errorMessage == null) return;

    _errorMessage = null;
    notifyListeners();
  }

  /// Retorna `true` si s'ha iniciat la sessió. La pantalla no ha de navegar:
  /// el canvi de sessió arriba per `AuthRepository.authStateChanges`.
  Future<bool> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    if (_isLoading || _isDisposed) return false;

    _errorMessage = null;
    _fieldErrors
      ..clear()
      // `?` només afegeix l'entrada si el validador retorna un error.
      ..addAll({
        LoginField.usernameOrEmail: ?AuthValidators.notEmpty(
          usernameOrEmail,
          message: "Introdueix el nom d'usuari o el correu.",
        ),
        LoginField.password: ?AuthValidators.notEmpty(
          password,
          message: 'Introdueix la contrasenya.',
        ),
      });

    if (_fieldErrors.isNotEmpty) {
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.signIn(
        usernameOrEmail: usernameOrEmail.trim(),
        password: password,
      );
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

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
