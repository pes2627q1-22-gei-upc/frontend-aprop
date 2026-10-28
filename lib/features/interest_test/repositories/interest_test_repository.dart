import '../models/interest_question.dart';

abstract interface class InterestTestRepository {
  /// Activities to answer. Throws on failure; an empty list is valid.
  Future<List<InterestQuestion>> getQuestions();

  /// Stores all answers and recalculates the user's interests. Throws on failure.
  Future<void> submitAnswers(List<InterestAnswer> answers);
}
