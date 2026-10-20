import 'dart:async';

import 'package:aprop/features/assistant/models/assistant_message.dart';
import 'package:aprop/features/assistant/presentation/view_models/assistant_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_assistant_repository.dart';

void main() {
  late FakeAssistantRepository repository;
  late AssistantViewModel viewModel;

  setUp(() {
    repository = FakeAssistantRepository();
    viewModel = AssistantViewModel(
      repository: repository,
      clock: () => DateTime(2026, 9, 26, 12),
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('Starts with welcome message from assistant', () {
    expect(viewModel.messages.length, 1);
    expect(viewModel.messages.first.sender, AssistantMessageSender.assistant);
    expect(viewModel.messages.first.text, AssistantViewModel.welcomeText);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.errorMessage, isNull);
  });

  test('Ignores empty or whitespace-only queries', () async {
    await viewModel.sendMessage('   ');
    expect(repository.receivedQueries, isEmpty);
    expect(viewModel.messages.length, 1);
  });

  test(
    'Appends user message, sets loading, and appends assistant reply',
    () async {
      final completer = Completer<AssistantMessage>();
      repository.onSendMessage = (_) => completer.future;

      final future = viewModel.sendMessage('  Jazz a Barcelona  ');
      expect(viewModel.isLoading, isTrue);
      expect(viewModel.messages.length, 2);
      expect(viewModel.messages[1].sender, AssistantMessageSender.user);
      expect(viewModel.messages[1].text, 'Jazz a Barcelona');

      // Duplicate calls while loading are ignored.
      await viewModel.sendMessage('Una altra consulta');
      expect(repository.receivedQueries, ['Jazz a Barcelona']);

      completer.complete(
        AssistantMessage.assistant(
          id: 'reply-1',
          text: 'He trobat 1 activitat:',
          sentAt: DateTime(2026, 9, 26, 12, 1),
        ),
      );
      await future;

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.messages.length, 3);
      expect(viewModel.messages[2].sender, AssistantMessageSender.assistant);
      expect(viewModel.messages[2].text, 'He trobat 1 activitat:');
    },
  );

  test(
    'Records error on failure and retries without duplicating user message',
    () async {
      var shouldFail = true;
      repository.onSendMessage = (query) async {
        if (shouldFail) throw Exception('network error');
        return AssistantMessage.assistant(
          id: 'reply-recovered',
          text: 'Resposta recuperada per a $query',
          sentAt: DateTime(2026, 9, 26, 12, 2),
        );
      };

      await viewModel.sendMessage('Exposicions a Girona');
      expect(viewModel.isLoading, isFalse);
      expect(
        viewModel.errorMessage,
        'No hem pogut obtenir les recomanacions de l’assistent. Torna-ho a provar.',
      );
      expect(viewModel.canRetry, isTrue);
      expect(viewModel.messages.length, 2);

      shouldFail = false;
      await viewModel.retryLastMessage();
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.canRetry, isFalse);
      expect(viewModel.messages.length, 3);
      expect(
        viewModel.messages[2].text,
        'Resposta recuperada per a Exposicions a Girona',
      );
      expect(repository.receivedQueries, [
        'Exposicions a Girona',
        'Exposicions a Girona',
      ]);
    },
  );

  test('Ignores late responses after dispose', () async {
    final completer = Completer<AssistantMessage>();
    repository.onSendMessage = (_) => completer.future;

    final localViewModel = AssistantViewModel(repository: repository);
    var notifications = 0;
    localViewModel.addListener(() => notifications++);

    final future = localViewModel.sendMessage('Teatre');
    expect(notifications, 1);

    localViewModel.dispose();
    completer.complete(
      AssistantMessage.assistant(
        id: 'late',
        text: 'Massa tard',
        sentAt: DateTime(2026, 9, 26, 12),
      ),
    );
    await future;

    expect(notifications, 1);
  });
}
