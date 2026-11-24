import '../models/interest_question.dart';

abstract interface class InterestTestRepository {
  /// Completion, onboarding prompt, and partial-progress status for the user.
  /// Throws on failure.
  Future<InterestTestStatus> getTestStatus();

  /// Marks that onboarding has already prompted this user so skipping or
  /// closing the app never forces the test again. Throws on failure.
  Future<void> markOnboardingPrompted();

  /// Remaining activities to answer (already-answered partial events excluded).
  /// Throws on failure; an empty list is valid.
  Future<List<InterestQuestion>> getQuestions();

  /// Stores answers and recalculates interests (when [partial] is false), or
  /// saves partial progress to resume later (when [partial] is true).
  /// Throws on failure.
  Future<void> submitAnswers(
    List<InterestAnswer> answers, {
    bool partial = false,
  });
}
