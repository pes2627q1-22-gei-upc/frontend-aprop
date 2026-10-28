import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../view_models/assistant_view_model.dart';
import '../widgets/assistant_input_bar.dart';
import '../widgets/assistant_message_bubble.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({
    super.key,
    required this.viewModel,
    required this.onActivitySelected,
    this.participationActionBuilder,
  });

  final AssistantViewModel viewModel;
  final ValueChanged<String> onActivitySelected;
  final Widget Function(Activity activity)? participationActionBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistent'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Tornar enrere',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, child) {
            final messages = viewModel.messages;
            final isLoading = viewModel.isLoading;
            final errorMessage = viewModel.errorMessage;
            final extraItems =
                (isLoading ? 1 : 0) + (errorMessage != null ? 1 : 0);

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    key: const PageStorageKey<String>('assistant-messages'),
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + extraItems,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index < messages.length) {
                        final message = messages[index];
                        return AssistantMessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          onActivitySelected: onActivitySelected,
                          participationActionBuilder:
                              participationActionBuilder,
                        );
                      }

                      if (isLoading && index == messages.length) {
                        return const _AssistantLoadingIndicator();
                      }

                      return _AssistantErrorBanner(
                        message: errorMessage!,
                        onRetry: viewModel.retryLastMessage,
                      );
                    },
                  ),
                ),
                AssistantInputBar(
                  isLoading: isLoading,
                  onSend: viewModel.sendMessage,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AssistantLoadingIndicator extends StatelessWidget {
  const _AssistantLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                  semanticsLabel: 'Cercant recomanacions',
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Cercant recomanacions…',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantErrorBanner extends StatelessWidget {
  const _AssistantErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.error),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: colors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tornar-ho a provar'),
            ),
          ],
        ),
      ),
    );
  }
}
