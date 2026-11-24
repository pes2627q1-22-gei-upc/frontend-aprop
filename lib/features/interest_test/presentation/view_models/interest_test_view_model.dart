import 'package:flutter/foundation.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/interest_question.dart';
import '../../repositories/interest_test_repository.dart';

class InterestTestViewModel extends ChangeNotifier {
  InterestTestViewModel({required this.repository, this.initialAnsweredCount});

  final InterestTestRepository repository;

  /// Optional previously answered count when the caller already fetched status
  /// (e.g. onboarding gate) to avoid a redundant status request.
  final int? initialAnsweredCount;

  List<InterestQuestion> _questions = const [];
  final _answers = <InterestAnswer>[];
  int _previouslyAnsweredCount = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isSavingPartial = false;
  bool _isCompleted = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _submitError;
  String? _partialSaveError;

  List<InterestQuestion> get questions => _questions;
  int get previouslyAnsweredCount => _previouslyAnsweredCount;
  int get totalCount => _previouslyAnsweredCount + _questions.length;
  int get answeredCount => _previouslyAnsweredCount + _answers.length;
  bool get hasUnsavedAnswers => _answers.isNotEmpty && !_isCompleted;
  InterestQuestion? get current =>
      _answers.length < _questions.length ? _questions[_answers.length] : null;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isSavingPartial => _isSavingPartial;
  bool get isCompleted => _isCompleted;
  String? get errorMessage => _errorMessage;
  String? get submitError => _submitError;
  String? get partialSaveError => _partialSaveError;

  Future<void> load() async {
    if (_isDisposed || _isLoading || _isSubmitting || _isSavingPartial) return;
    _isLoading = true;
    _errorMessage = null;
    _submitError = null;
    _partialSaveError = null;
    _isCompleted = false;
    _answers.clear();
    _previouslyAnsweredCount = initialAnsweredCount ?? 0;
    notifyListeners();
    try {
      final statusFuture = initialAnsweredCount != null
          ? null
          : repository.getTestStatus().then<InterestTestStatus?>(
              (s) => s,
              onError: (_) => null,
            );
      final result = await repository.getQuestions();
      final status = statusFuture != null ? await statusFuture : null;
      if (!_isDisposed) {
        _questions = result;
        if (status != null) {
          _previouslyAnsweredCount = status.answeredCount;
        }
      }
    } catch (_) {
      if (!_isDisposed) {
        _errorMessage = currentL10n.interestTestLoadError;
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
    if (_isDisposed || question == null || _isSubmitting || _isSavingPartial) {
      return;
    }
    _partialSaveError = null;
    _answers.add(InterestAnswer(eventId: question.eventId, likes: likes));
    notifyListeners();
    if (current == null) await submit();
  }

  /// Saves partial progress («Més tard») without completing the test or
  /// discarding previously saved answers. Returns `true` when there is nothing
  /// to save or when saving succeeds.
  Future<bool> savePartialProgress() async {
    if (_isDisposed || _isSubmitting || _isSavingPartial) return false;
    if (_answers.isEmpty || _isCompleted) return true;

    _isSavingPartial = true;
    _partialSaveError = null;
    notifyListeners();
    try {
      final toSave = List<InterestAnswer>.unmodifiable(_answers);
      await repository.submitAnswers(toSave, partial: true);
      if (!_isDisposed) {
        _previouslyAnsweredCount += toSave.length;
        _questions = _questions.length > toSave.length
            ? List.unmodifiable(_questions.sublist(toSave.length))
            : const [];
        _answers.clear();
      }
      return true;
    } catch (_) {
      if (!_isDisposed) {
        _partialSaveError = currentL10n.interestTestSaveError;
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _isSavingPartial = false;
        notifyListeners();
      }
    }
  }

  Future<void> submit() async {
    if (_isDisposed ||
        _isSubmitting ||
        _isSavingPartial ||
        _isCompleted ||
        _answers.isEmpty) {
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
        _submitError = currentL10n.interestTestSaveError;
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
