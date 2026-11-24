import 'package:flutter/material.dart';

/// Minimal, zero-dependency inline markdown renderer for assistant messages.
///
/// Supports `**bold**`, `***bold italic***`, `*italic*`, `` `code` ``,
/// leading `- ` / `* ` bullet items (rendered as `• `) and `#` headings.
/// Unclosed or mismatched delimiters stay literal without throwing.
class AssistantMarkdownText extends StatelessWidget {
  const AssistantMarkdownText({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(buildAssistantMarkdownSpan(text, style: style));
  }
}

/// Returns the plain text shown by [AssistantMarkdownText], without raw
/// markdown markers, suitable for screen-reader announcements.
String assistantMarkdownPlainText(String text) =>
    buildAssistantMarkdownSpan(text).toPlainText();

/// Parses [text] into a styled [TextSpan] tree rooted at [style].
TextSpan buildAssistantMarkdownSpan(String text, {TextStyle? style}) {
  final normalized = text.replaceAll('\r\n', '\n');
  if (normalized.isEmpty) {
    return TextSpan(text: '', style: style);
  }

  final lines = normalized.split('\n');
  final children = <InlineSpan>[];

  for (var i = 0; i < lines.length; i++) {
    if (i > 0) {
      children.add(const TextSpan(text: '\n'));
    }
    _parseLine(lines[i], children);
  }

  if (children.length == 1) {
    final only = children.first;
    if (only is TextSpan && only.style == null && only.children == null) {
      return TextSpan(text: only.text, style: style);
    }
  }

  return TextSpan(style: style, children: children);
}

final RegExp _headingLinePattern = RegExp(r'^\s{0,3}#{1,6}\s+(.+)$');
final RegExp _bulletLinePattern = RegExp(r'^(\s*)[-*]\s+(.*)$');

void _parseLine(String line, List<InlineSpan> out) {
  final heading = _headingLinePattern.firstMatch(line);
  if (heading != null) {
    _parseInline(heading.group(1)!, out, bold: true, italic: false);
    return;
  }

  final bullet = _bulletLinePattern.firstMatch(line);
  if (bullet != null) {
    final indent = bullet.group(1)!;
    out.add(TextSpan(text: '$indent• '));
    _parseInline(bullet.group(2)!, out, bold: false, italic: false);
    return;
  }

  _parseInline(line, out, bold: false, italic: false);
}

void _parseInline(
  String input,
  List<InlineSpan> out, {
  required bool bold,
  required bool italic,
}) {
  var plainStart = 0;

  void flushPlain(int end) {
    if (end > plainStart) {
      out.add(
        _styledSpan(
          input.substring(plainStart, end),
          bold: bold,
          italic: italic,
        ),
      );
    }
  }

  var i = 0;
  while (i < input.length) {
    final code = input.codeUnitAt(i);

    if (code == 0x2A /* '*' */ ) {
      // Bold + italic: ***...***
      if (input.startsWith('***', i) &&
          i + 3 < input.length &&
          !_isSpace(input.codeUnitAt(i + 3)) &&
          input.codeUnitAt(i + 3) != 0x2A) {
        final close = _findClosingDelimiter(input, '***', i + 3);
        if (close > i + 3) {
          flushPlain(i);
          _parseInline(
            input.substring(i + 3, close),
            out,
            bold: true,
            italic: true,
          );
          i = close + 3;
          plainStart = i;
          continue;
        }
      }

      // Bold: **...**
      if (input.startsWith('**', i) &&
          i + 2 < input.length &&
          !_isSpace(input.codeUnitAt(i + 2)) &&
          input.codeUnitAt(i + 2) != 0x2A) {
        final close = _findClosingDelimiter(input, '**', i + 2);
        if (close > i + 2) {
          flushPlain(i);
          _parseInline(
            input.substring(i + 2, close),
            out,
            bold: true,
            italic: italic,
          );
          i = close + 2;
          plainStart = i;
          continue;
        }
      }

      // Italic: *...*
      if (!input.startsWith('**', i) &&
          i + 1 < input.length &&
          !_isSpace(input.codeUnitAt(i + 1)) &&
          input.codeUnitAt(i + 1) != 0x2A) {
        final close = _findClosingSingleAsterisk(input, i + 1);
        if (close > i + 1) {
          flushPlain(i);
          _parseInline(
            input.substring(i + 1, close),
            out,
            bold: bold,
            italic: true,
          );
          i = close + 1;
          plainStart = i;
          continue;
        }
      }
    } else if (code == 0x60 /* '`' */ ) {
      final close = input.indexOf('`', i + 1);
      if (close > i + 1) {
        flushPlain(i);
        out.add(
          _styledSpan(
            input.substring(i + 1, close),
            bold: bold,
            italic: italic,
            code: true,
          ),
        );
        i = close + 1;
        plainStart = i;
        continue;
      }
    }

    i++;
  }

  flushPlain(input.length);
}

int _findClosingDelimiter(String input, String delimiter, int start) {
  var searchFrom = start;
  while (searchFrom < input.length) {
    final idx = input.indexOf(delimiter, searchFrom);
    if (idx == -1) return -1;
    if (idx > start && !_isSpace(input.codeUnitAt(idx - 1))) {
      return idx;
    }
    searchFrom = idx + 1;
  }
  return -1;
}

int _findClosingSingleAsterisk(String input, int start) {
  for (var i = start; i < input.length; i++) {
    if (input.codeUnitAt(i) != 0x2A) continue;
    if (i + 1 < input.length && input.codeUnitAt(i + 1) == 0x2A) {
      while (i + 1 < input.length && input.codeUnitAt(i + 1) == 0x2A) {
        i++;
      }
      continue;
    }
    if (i > start && !_isSpace(input.codeUnitAt(i - 1))) {
      return i;
    }
  }
  return -1;
}

bool _isSpace(int codeUnit) =>
    codeUnit == 0x20 ||
    codeUnit == 0x09 ||
    codeUnit == 0x0A ||
    codeUnit == 0x0D;

TextSpan _styledSpan(
  String text, {
  required bool bold,
  required bool italic,
  bool code = false,
}) {
  if (!bold && !italic && !code) {
    return TextSpan(text: text);
  }
  return TextSpan(
    text: text,
    style: TextStyle(
      fontWeight: bold ? FontWeight.bold : (code ? FontWeight.w600 : null),
      fontStyle: italic ? FontStyle.italic : null,
    ),
  );
}
