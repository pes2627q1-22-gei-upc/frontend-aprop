import 'package:flutter/foundation.dart';

import '../../models/interest_question.dart';
import '../../repositories/interest_test_repository.dart';

class InterestTestViewModel extends ChangeNotifier {
  InterestTestViewModel({required this.repository});

  final InterestTestRepository repository;
  List<InterestQuestion> _questions = const [];
  final _answers = <InterestAnswer>[];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isCompleted = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _submitError;

  List<InterestQuestion> get questions => _questions;
  int get answeredCount => _answers.length;
  InterestQuestion? get current =>
      _answers.length < _questions.length ? _questions[_answers.length] : null;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isCompleted => _isCompleted;
  String? get errorMessage => _errorMessage;
  String? get submitError => _submitError;

  Future<void> load() async {
    if (_isDisposed || _isLoading || _isSubmitting) return;
    _isLoading = true;
    _errorMessage = null;
    _submitError = null;
    _isCompleted = false;
    _answers.clear();
    notifyListeners();
    try {
      final result = await repository.getQuestions();
      if (!_isDisposed) _questions = result;
    } catch (_) {
      if (!_isDisposed) {
        _errorMessage = 'No hem pogut carregar el test. Torna-ho a provar.';
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Records the answer for [current]; after the last one, sends them all.
  Future<void> answer({required bool likes}) async {
    final question = current;
    if (_isDisposed || question == null || _isSubmitting) return;
    _answers.add(InterestAnswer(eventId: question.eventId, likes: likes));
    notifyListeners();
    if (current == null) await submit();
  }

  Future<void> submit() async {
    if (_isDisposed || _isSubmitting || _isCompleted || _answers.isEmpty) {
      return;
    }
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();
    try {
      await repository.submitAnswers(List.unmodifiable(_answers));
      if (!_isDisposed) _isCompleted = true;
    } catch (_) {
      if (!_isDisposed) {
        _submitError = 'No hem pogut desar les respostes. Torna-ho a provar.';
      }
    } finally {
      if (!_isDisposed) {
        _isSubmitting = false;
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
