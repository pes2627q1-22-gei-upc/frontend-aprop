import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/auth_failure.dart';
import '../../repositories/auth_repository.dart';
import 'auth_failure_message.dart';

const emailNotVerifiedMessage =
    "Encara no consta que hagis verificat el correu. Obre l'enllaç que t'hem "
    'enviat i torna-ho a provar.';
const verificationEmailSentMessage = "T'hem tornat a enviar el correu.";

class VerifyEmailViewModel extends ChangeNotifier {
  /// La pantalla s'obre just després d'enviar el correu (o d'entrar amb un
  /// compte sense verificar), així que el compte enrere comença de seguida.
  VerifyEmailViewModel({
    required this._repository,
    this.resendCooldown = const Duration(seconds: 30),
  }) {
    _startCooldown();
  }

  final AuthRepository _repository;

  /// Temps d'espera entre enviaments, perquè no es reenviï el correu sense
  /// parar.
  final Duration resendCooldown;

  Timer? _cooldownTimer;
  int _cooldownSecondsLeft = 0;
  bool _isChecking = false;
  bool _isResending = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _infoMessage;

  bool get isChecking => _isChecking;
  bool get isResending => _isResending;
  bool get isBusy => _isChecking || _isResending;
  int get cooldownSecondsLeft => _cooldownSecondsLeft;
  bool get canResend => !isBusy && _cooldownSecondsLeft == 0;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;

  /// Si el correu ja està verificat no cal fer res més: el canvi arriba per
  /// `AuthRepository.authStateChanges` i `AuthGate` mostra l'app.
  Future<void> checkVerification() async {
    if (isBusy || _isDisposed) return;

    _isChecking = true;
    _startAction();

    try {
      final verified = await _repository.checkEmailVerified();
      if (!verified) _errorMessage = emailNotVerifiedMessage;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
    } catch (_) {
      _errorMessage = unexpectedAuthErrorMessage;
    } finally {
      _isChecking = false;
      _finishAction();
    }
  }

  Future<void> resendEmail() async {
    if (!canResend || _isDisposed) return;

    _isResending = true;
    _startAction();

    try {
      await _repository.sendEmailVerification();
      _infoMessage = verificationEmailSentMessage;
      // Si l'enviament falla no esperem: es pot tornar a provar de seguida.
      if (!_isDisposed) _startCooldown();
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
    } catch (_) {
      _errorMessage = unexpectedAuthErrorMessage;
    } finally {
      _isResending = false;
      _finishAction();
    }
  }

  /// Sortida per a qui s'ha equivocat de correu: sense sessió, `AuthGate`
  /// torna a mostrar el login.
  Future<void> signOut() async {
    if (_isDisposed) return;

    try {
      await _repository.signOut();
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = unexpectedAuthErrorMessage;
      _infoMessage = null;
      notifyListeners();
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

  void _startAction() {
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }

  void _finishAction() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
