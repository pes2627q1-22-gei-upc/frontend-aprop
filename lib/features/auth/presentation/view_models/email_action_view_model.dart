import 'package:flutter/foundation.dart';

import '../../models/auth_failure.dart';
import '../../models/email_action.dart';
import '../../repositories/auth_repository.dart';
import 'auth_failure_message.dart';

// TODO(DP-031): textos sense mockup.
const expiredEmailLinkMessage =
    "Aquest enllaç ha caducat o ja s'ha fet servir. Des de l'app, torna a "
    'enviar el correu i obre el més recent.';

enum EmailActionStatus { verifying, verified, failed, unsupported }

/// Pàgina de la web que obren els enllaços dels correus (DP-031): confirma el
/// codi de verificació amb la clau de l'app, sense necessitat de sessió.
class EmailActionViewModel extends ChangeNotifier {
  EmailActionViewModel({required this._repository, required this.action})
    : _status = action.isEmailVerification
          ? EmailActionStatus.verifying
          : EmailActionStatus.unsupported;

  final AuthRepository _repository;
  final EmailAction action;

  EmailActionStatus _status;
  String? _errorMessage;
  bool _hasStarted = false;
  bool _isDisposed = false;

  EmailActionStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// Només es confirma un cop: el codi és d'un sol ús.
  Future<void> start() async {
    if (_hasStarted || _isDisposed || !action.isEmailVerification) return;
    _hasStarted = true;

    try {
      await _repository.confirmEmailVerification(action.code);
      _status = EmailActionStatus.verified;
    } on AuthFailure catch (failure) {
      _status = EmailActionStatus.failed;
      _errorMessage = failure == AuthFailure.invalidVerificationLink
          ? expiredEmailLinkMessage
          : failure.message;
    } catch (_) {
      _status = EmailActionStatus.failed;
      _errorMessage = unexpectedAuthErrorMessage;
    }
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
