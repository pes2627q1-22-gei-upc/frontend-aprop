import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../../activities/models/activity.dart';
import '../../models/assistant_message.dart';
import '../view_models/assistant_view_model.dart';
import '../widgets/assistant_input_bar.dart';
import '../widgets/assistant_markdown_text.dart';
import '../widgets/assistant_message_bubble.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    required this.viewModel,
    required this.onActivitySelected,
    this.participationActionBuilder,
    this.onOpenScreen,
  });

  final AssistantViewModel viewModel;
  final ValueChanged<String> onActivitySelected;
  final Widget Function(Activity activity)? participationActionBuilder;

  /// Opens an app screen suggested by an assistant reply. Null hides the button.
  final ValueChanged<AssistantScreenTarget>? onOpenScreen;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;
  bool _lastIsLoading = false;
  final _showJumpToEnd = ValueNotifier<bool>(false);
  // Messages already on screen when the page opened do not animate in.
  late final Set<String> _seen = {for (final m in _viewModel.messages) m.id};

  AssistantViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _lastMessageCount = _viewModel.messages.length;
    _lastIsLoading = _viewModel.isLoading;
    _viewModel.addListener(_onViewModelChanged);
    _scrollController.addListener(_onScroll);
    _viewModel.loadSuggestions();
    // Reopening the screen must also land on the newest message.
    _jumpToBottom();
  }

  @override
  void didUpdateWidget(AssistantScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      _lastMessageCount = _viewModel.messages.length;
      _lastIsLoading = _viewModel.isLoading;
      _viewModel.addListener(_onViewModelChanged);
      _viewModel.loadSuggestions();
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _scrollController.dispose();
    _showJumpToEnd.dispose();
    super.dispose();
  }

  int get _itemCount =>
      _viewModel.messages.length +
      (_viewModel.isLoading ? 1 : 0) +
      (_viewModel.errorMessage != null ? 1 : 0) +
      (_starterVisible ? 1 : 0);

  bool get _starterVisible =>
      _viewModel.suggestions.isNotEmpty &&
      !_viewModel.messages.any((m) => m.sender == AssistantMessageSender.user);

  void _onViewModelChanged() {
    final messages = _viewModel.messages;
    final isLoading = _viewModel.isLoading;
    if (messages.length > _lastMessageCount &&
        messages.last.sender == AssistantMessageSender.assistant) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.l10n.assistantAnnouncement(
          assistantMarkdownPlainText(messages.last.text),
        ),
        Directionality.of(context),
      );
    }
    final messageCountChanged = messages.length != _lastMessageCount;
    final loadingChanged = isLoading != _lastIsLoading;
    _lastMessageCount = messages.length;
    _lastIsLoading = isLoading;

    if (_viewModel.feedbackError case final error?) {
      _viewModel.clearFeedbackError();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }

    // Scroll to the newest row only when messages arrive or loading state changes.
    // Rating an earlier answer, fetching suggestions or feedback errors must
    // not jump to the bottom and interrupt the user's reading.
    if (messageCountChanged || loadingChanged) {
      _scrollToBottom();
    }
  }

  void _onScroll() {
    final position = _scrollController.position;
    _showJumpToEnd.value = position.maxScrollExtent - position.pixels > 160;
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.assistantTitle),
        centerTitle: true,
        leading: IconButton(
          tooltip: context.l10n.goBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) {
            final messages = _viewModel.messages;
            final isLoading = _viewModel.isLoading;
            final errorMessage = _viewModel.errorMessage;
            final suggestions = _viewModel.suggestions;
            // Before the first question the chips are starter cards in the
            // list; afterwards they live in a strip above the input.
            final starter =
                suggestions.isNotEmpty &&
                !messages.any((m) => m.sender == AssistantMessageSender.user);

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ListView.separated(
                          key: const PageStorageKey<String>(
                            'assistant-messages',
                          ),
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _itemCount,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index < messages.length) {
                              final message = messages[index];
                              final animate = _seen.add(message.id);
                              return _Appear(
                                key: ValueKey('appear-${message.id}'),
                                animate: animate,
                                child: AssistantMessageBubble(
                                  key: ValueKey(message.id),
                                  message: message,
                                  onActivitySelected: widget.onActivitySelected,
                                  participationActionBuilder:
                                      widget.participationActionBuilder,
                                  rating: _viewModel.ratingOf(message),
                                  onRate: _viewModel.canRate(message)
                                      ? (helpful) => _viewModel.rate(
                                          message,
                                          helpful: helpful,
                                        )
                                      : null,
                                  onOpenScreen: widget.onOpenScreen,
                                ),
                              );
                            }

                            var extra = index - messages.length;
                            if (starter) {
                              if (extra == 0) {
                                return _Appear(
                                  key: const ValueKey('appear-starters'),
                                  animate: true,
                                  child: _SuggestionChips(
                                    suggestions: suggestions,
                                    enabled: !isLoading,
                                    onSelected: _viewModel.sendMessage,
                                    wrap: true,
                                  ),
                                );
                              }
                              extra -= 1;
                            }

                            if (isLoading && extra == 0) {
                              return const _Appear(
                                key: ValueKey('appear-typing'),
                                animate: true,
                                child: _TypingIndicator(),
                              );
                            }

                            return _Appear(
                              key: ValueKey('appear-error-$errorMessage'),
                              animate: true,
                              child: _AssistantErrorBanner(
                                message: errorMessage!,
                                onRetry: _viewModel.retryLastMessage,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 12,
                        child: _JumpToEndButton(
                          visible: _showJumpToEnd,
                          onPressed: _scrollToBottom,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.bottomCenter,
                  child: suggestions.isNotEmpty && !starter
                      ? _SuggestionChips(
                          suggestions: suggestions,
                          enabled: !isLoading,
                          onSelected: _viewModel.sendMessage,
                        )
                      : const SizedBox(width: double.infinity),
                ),
                AssistantInputBar(
                  isLoading: isLoading,
                  onSend: _viewModel.sendMessage,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({
    required this.suggestions,
    required this.enabled,
    required this.onSelected,
    this.wrap = false,
  });

  final List<String> suggestions;
  final bool enabled;
  final ValueChanged<String> onSelected;

  /// Starter layout (wrapping, in the list) instead of the one-line strip.
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final text in suggestions)
        Semantics(
          button: true,
          enabled: enabled,
          label: context.l10n.assistantSuggestedQuestion(text),
          excludeSemantics: true,
          child: ActionChip(
            label: Text(text),
            onPressed: enabled ? () => onSelected(text) : null,
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
    ];
    if (wrap) return Wrap(spacing: 8, runSpacing: 8, children: chips);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          for (final chip in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: chip),
        ],
      ),
    );
  }
}

/// Fades and slides a new row in once. Rows already on screen, and users who
/// asked for reduced motion, appear instantly.
class _Appear extends StatefulWidget {
  const _Appear({super.key, required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  State<_Appear> createState() => _AppearState();
}

class _AppearState extends State<_Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.animate && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Three bouncing dots in an assistant-style bubble while a reply is pending.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        label: context.l10n.assistantSearching,
        excludeSemantics: true,
        child: DecoratedBox(
          key: const ValueKey('assistant-typing'),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outlineVariant),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      child: Opacity(
                        opacity: 0.35 + 0.65 * _pulse(i),
                        child: Transform.translate(
                          offset: Offset(0, -4 * _pulse(i)),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 0..1 bump, delayed by 0.2 of the cycle per dot.
  double _pulse(int dot) {
    final t = (_controller.value - dot * 0.2) % 1.0;
    return t < 0.4 ? math.sin(t / 0.4 * math.pi) : 0;
  }
}

class _JumpToEndButton extends StatelessWidget {
  const _JumpToEndButton({required this.visible, required this.onPressed});

  final ValueListenable<bool> visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, show, child) => IgnorePointer(
        ignoring: !show,
        child: AnimatedScale(
          scale: show ? 1 : 0.6,
          duration: const Duration(milliseconds: 180),
          child: AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: child,
          ),
        ),
      ),
      child: Semantics(
        button: true,
        label: context.l10n.assistantGoToLast,
        excludeSemantics: true,
        child: IconButton.filledTonal(
          tooltip: context.l10n.assistantGoToLast,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: onPressed,
          icon: const Icon(Icons.keyboard_arrow_down),
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
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
