import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/auth_failure.dart';
import '../../repositories/auth_repository.dart';
import 'auth_failure_message.dart';
import 'auth_validators.dart';

/// No diu si hi ha cap compte amb el correu: es mostra igual en tots dos casos.
const passwordResetSentMessage =
    "Si hi ha un compte amb aquest correu, t'hi hem enviat un enllaç per "
    'triar una contrasenya nova. Si no el trobes, mira el correu brossa.';

/// Formulari per demanar l'enllaç de «He oblidat la contrasenya».
class ForgotPasswordViewModel extends ChangeNotifier {
  ForgotPasswordViewModel({
    required this._repository,
    this.resendCooldown = const Duration(seconds: 60),
  });

  final AuthRepository _repository;

  /// Temps d'espera entre enviaments, perquè no es pugui enviar el correu sense
  /// parar (CA2). Com amb la verificació del correu, Firebase també limita els
  /// enviaments seguits a la mateixa adreça.
  final Duration resendCooldown;

  Timer? _cooldownTimer;
  int _cooldownSecondsLeft = 0;
  bool _isSending = false;
  bool _hasSent = false;
  bool _isDisposed = false;
  String? _emailError;
  String? _errorMessage;
  String? _infoMessage;

  bool get isSending => _isSending;

  /// Cert un cop s'ha enviat l'enllaç almenys una vegada.
  bool get hasSent => _hasSent;
  int get cooldownSecondsLeft => _cooldownSecondsLeft;
  bool get canSend => !_isSending && _cooldownSecondsLeft == 0;
  String? get emailError => _emailError;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;

  /// L'usuari ha canviat el correu: l'error anterior ja no hi correspon.
  void onEmailChanged() {
    if (_emailError == null && _errorMessage == null) return;
    _emailError = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> send(String email) async {
    if (!canSend || _isDisposed) return;

    _emailError = AuthValidators.email(email);
    _errorMessage = null;
    if (_emailError != null) {
      notifyListeners();
      return;
    }

    _isSending = true;
    _infoMessage = null;
    notifyListeners();

    try {
      await _repository.sendPasswordResetEmail(email.trim());
      if (_isDisposed) return;
      _hasSent = true;
      _infoMessage = passwordResetSentMessage;
      _startCooldown();
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
    } catch (_) {
      _errorMessage = unexpectedAuthErrorMessage;
    } finally {
      if (!_isDisposed) {
        _isSending = false;
        notifyListeners();
      }
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownSecondsLeft = resendCooldown.inSeconds;
    if (_cooldownSecondsLeft == 0) return;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _cooldownSecondsLeft--;
      if (_cooldownSecondsLeft == 0) timer.cancel();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
