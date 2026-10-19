import 'package:flutter/material.dart';

class AssistantInputBar extends StatefulWidget {
  const AssistantInputBar({
    super.key,
    required this.isLoading,
    required this.onSend,
  });

  final bool isLoading;
  final ValueChanged<String> onSend;

  @override
  State<AssistantInputBar> createState() => _AssistantInputBarState();
}

class _AssistantInputBarState extends State<AssistantInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasNonEmptyText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasNonEmptyText) {
      setState(() {
        _hasNonEmptyText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty || widget.isLoading) return;
    _controller.clear();
    widget.onSend(query);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canSend = _hasNonEmptyText && !widget.isLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Tooltip(
              message: 'Entrada per veu disponible properament',
              child: IconButton(
                onPressed: null,
                icon: const Icon(Icons.mic_none_outlined),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const ValueKey('assistant-query-field'),
                controller: _controller,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 3,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Escriu una consulta…',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: canSend ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
