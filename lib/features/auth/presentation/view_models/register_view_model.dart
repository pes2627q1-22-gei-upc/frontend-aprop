import 'package:flutter/foundation.dart';

import '../../models/auth_failure.dart';
import '../../repositories/auth_repository.dart';
import 'auth_failure_message.dart';
import 'auth_validators.dart';

enum RegisterField {
  firstName,
  lastName,
  username,
  email,
  password,
  passwordConfirmation,
}

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel({required this._repository});

  final AuthRepository _repository;

  final Map<RegisterField, String> _fieldErrors = {};
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? fieldError(RegisterField field) => _fieldErrors[field];

  /// L'usuari ha modificat un camp: en treu l'error i el missatge general.
  /// Es tornaran a comprovar quan torni a enviar el formulari.
  void onFieldChanged(RegisterField field) {
    final hadFieldError = _fieldErrors.remove(field) != null;
    if (!hadFieldError && _errorMessage == null) return;

    _errorMessage = null;
    notifyListeners();
  }

  /// Retorna `true` si s'ha creat el compte. Llavors la pantalla de registre
  /// s'ha de tancar perquè quedi visible el que mostri la sessió nova.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (_isLoading || _isDisposed) return false;

    _errorMessage = null;
    _fieldErrors
      ..clear()
      // `?` només afegeix l'entrada si el validador retorna un error.
      ..addAll({
        RegisterField.firstName: ?AuthValidators.notEmpty(
          firstName,
          message: 'Introdueix el nom.',
        ),
        RegisterField.lastName: ?AuthValidators.notEmpty(
          lastName,
          message: 'Introdueix els cognoms.',
        ),
        RegisterField.username: ?AuthValidators.username(username),
        RegisterField.email: ?AuthValidators.email(email),
        RegisterField.password: ?AuthValidators.newPassword(password),
        RegisterField.passwordConfirmation:
            ?AuthValidators.passwordConfirmation(
              passwordConfirmation,
              password,
            ),
      });

    if (_fieldErrors.isNotEmpty) {
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.register(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        username: username.trim(),
        email: email.trim(),
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
