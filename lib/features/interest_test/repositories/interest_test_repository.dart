import '../models/interest_question.dart';

abstract interface class InterestTestRepository {
  /// Whether the current user has already completed the interest test.
  /// Throws on failure.
  Future<bool> hasCompletedTest();

  /// Activities to answer. Throws on failure; an empty list is valid.
  Future<List<InterestQuestion>> getQuestions();

  /// Stores all answers and recalculates the user's interests. Throws on failure.
  Future<void> submitAnswers(List<InterestAnswer> answers);
}
