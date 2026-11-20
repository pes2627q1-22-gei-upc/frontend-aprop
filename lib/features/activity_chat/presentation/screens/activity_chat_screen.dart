import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity_message.dart';
import '../../repositories/activity_chat_repository.dart';
import '../formatters/activity_message_formatter.dart';
import '../view_models/activity_chat_view_model.dart';

/// Xat d'una activitat amb les persones que s'hi han apuntat (fig. 9, R11).
class ActivityChatScreen extends StatefulWidget {
  const ActivityChatScreen({
    super.key,
    required this.activityId,
    required this.activityTitle,
    required this.userId,
    required this.repository,
    this.pollInterval = const Duration(seconds: 5),
    this.now = DateTime.now,
  });

  final String activityId;
  final String activityTitle;
  final String userId;
  final ActivityChatRepository repository;
  final Duration pollInterval;
  final DateTime Function() now;

  @override
  State<ActivityChatScreen> createState() => _ActivityChatScreenState();
}

class _ActivityChatScreenState extends State<ActivityChatScreen> {
  late final ActivityChatViewModel _viewModel = ActivityChatViewModel(
    activityId: widget.activityId,
    userId: widget.userId,
    repository: widget.repository,
    pollInterval: widget.pollInterval,
  )..load();
  final _text = TextEditingController();
  final _scroll = ScrollController();

  /// En segon pla el xat deixa de demanar missatges nous.
  late final _lifecycle = AppLifecycleListener(
    onPause: _viewModel.pause,
    onHide: _viewModel.pause,
    onShow: _viewModel.resume,
    onResume: _viewModel.resume,
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _viewModel.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await _viewModel.send(_text.text);
    if (!sent || !mounted) return;
    _text.clear();
    // La llista va de baix a dalt: el missatge nou és a la posició 0.
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.actChat),
            Text(
              widget.activityTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) => Column(
            children: [
              Expanded(child: _buildMessages(context)),
              _ChatInputBar(
                controller: _text,
                enabled: _viewModel.hasLoaded,
                isSending: _viewModel.isSending,
                error: _viewModel.sendError,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessages(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (!_viewModel.hasLoaded) {
      final error = _viewModel.errorMessage;
      if (error == null) {
        return Center(
          child: CircularProgressIndicator(semanticsLabel: l10n.actChat),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              // Sense inscripció, tornar-ho a provar no serveix de res.
              if (_viewModel.isNotEnrolled)
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(l10n.chatBackToActivity),
                )
              else
                FilledButton(
                  onPressed: _viewModel.load,
                  child: Text(l10n.retry),
                ),
            ],
          ),
        ),
      );
    }

    final messages = _viewModel.messages;
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.chatEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final now = widget.now();
    final hasOlder = _viewModel.hasOlder;
    // Del més nou (a baix) al més antic (a dalt), com qualsevol xat.
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: messages.length + (hasOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) return _buildOlder(context);
        final position = messages.length - 1 - index;
        final message = messages[position];
        final previous = position > 0 ? messages[position - 1] : null;
        return _MessageBubble(
          key: ValueKey(message.key),
          message: message,
          isMine: _viewModel.isMine(message),
          // El nom només surt al primer d'uns quants missatges seguits.
          showAuthor: previous?.authorId != message.authorId,
          time: formatMessageTime(message.sentAt, now),
        );
      },
    );
  }

  Widget _buildOlder(BuildContext context) {
    final l10n = context.l10n;
    if (_viewModel.isLoadingOlder) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          if (_viewModel.olderError case final error?)
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          TextButton(
            onPressed: _viewModel.loadOlder,
            child: Text(l10n.chatOlder),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.showAuthor,
    required this.time,
  });

  final ActivityMessage message;
  final bool isMine;
  final bool showAuthor;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final author = isMine ? context.l10n.chatYou : message.authorName;
    final background = isMine ? colors.primary : colors.surfaceContainerHigh;
    final foreground = isMine ? colors.onPrimary : colors.onSurface;

    return Padding(
      padding: EdgeInsets.only(top: showAuthor ? 12 : 4),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: EdgeInsets.only(
              left: isMine ? 48 : 0,
              right: isMine ? 0 : 48,
            ),
            child: Semantics(
              container: true,
              label: '$author, $time',
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (showAuthor && !isMine)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: ExcludeSemantics(
                        child: Text(
                          author,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMine ? 18 : 6),
                        bottomRight: Radius.circular(isMine ? 6 : 18),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SelectableText(
                            message.text,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: foreground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ExcludeSemantics(
                            child: Text(
                              time,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: foreground.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
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
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.enabled,
    required this.isSending,
    required this.error,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final String? error;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error case final message?)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(message, style: TextStyle(color: colors.error)),
              ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final canSend =
                    enabled && !isSending && value.text.trim().isNotEmpty;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        enabled: enabled,
                        minLines: 1,
                        maxLines: 4,
                        // Límit en runes, com el backend (no en caràcters
                        // visibles: un emoji compost en compta més d'una).
                        inputFormatters: const [_RuneLimitFormatter()],
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (canSend) onSend();
                        },
                        decoration: InputDecoration(
                          hintText: l10n.chatInputHint,
                          // El comptador només surt quan s'acosta al límit.
                          counterText: switch (activityMessageLength(
                            value.text,
                          )) {
                            final length
                                when length > maxActivityMessageLength - 100 =>
                              '$length/$maxActivityMessageLength',
                            _ => null,
                          },
                          filled: true,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: canSend ? onSend : null,
                      tooltip: l10n.chatSend,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      icon: isSending
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Talla el text a [maxActivityMessageLength] runes sense partir cap caràcter.
class _RuneLimitFormatter extends TextInputFormatter {
  const _RuneLimitFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (activityMessageLength(newValue.text) <= maxActivityMessageLength) {
      return newValue;
    }
    // Es treuen caràcters visibles sencers del final fins que hi cap.
    final characters = newValue.text.characters.toList();
    var length = activityMessageLength(newValue.text);
    while (characters.isNotEmpty && length > maxActivityMessageLength) {
      length -= activityMessageLength(characters.removeLast());
    }
    final text = characters.join();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
