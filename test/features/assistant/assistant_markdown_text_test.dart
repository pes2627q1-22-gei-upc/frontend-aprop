import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/assistant/models/assistant_message.dart';
import 'package:aprop/features/assistant/presentation/widgets/assistant_markdown_text.dart';
import 'package:aprop/features/assistant/presentation/widgets/assistant_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<TextSpan> _leafSpans(InlineSpan span) {
  final result = <TextSpan>[];
  span.visitChildren((child) {
    if (child is TextSpan && child.text != null && child.text!.isNotEmpty) {
      result.add(child);
    }
    return true;
  });
  return result;
}

void main() {
  test('Renders **bold** spans without raw asterisks', () {
    final span = buildAssistantMarkdownSpan(
      'Et recomano **Les parets criden** i **Clave Gaudí**.',
    );

    expect(span.toPlainText(), 'Et recomano Les parets criden i Clave Gaudí.');
    expect(span.toPlainText(), isNot(contains('**')));

    final leaves = _leafSpans(span);
    expect(
      leaves
          .where((s) => s.style?.fontWeight == FontWeight.bold)
          .map((s) => s.text),
      ['Les parets criden', 'Clave Gaudí'],
    );
  });

  test('Renders bullets, italic, bold-italic, inline code and headings', () {
    final span = buildAssistantMarkdownSpan(
      '### Propostes\n'
      '- **Les parets criden**: una *gran* exposició\n'
      '* ***Clave Gaudí*** a `Barcelona`',
    );

    expect(
      span.toPlainText(),
      'Propostes\n'
      '• Les parets criden: una gran exposició\n'
      '• Clave Gaudí a Barcelona',
    );

    final leaves = _leafSpans(span);
    expect(
      leaves.any(
        (s) => s.text == 'Propostes' && s.style?.fontWeight == FontWeight.bold,
      ),
      isTrue,
    );
    expect(
      leaves.any(
        (s) => s.text == 'gran' && s.style?.fontStyle == FontStyle.italic,
      ),
      isTrue,
    );
    expect(
      leaves.any(
        (s) =>
            s.text == 'Clave Gaudí' &&
            s.style?.fontWeight == FontWeight.bold &&
            s.style?.fontStyle == FontStyle.italic,
      ),
      isTrue,
    );
    expect(
      leaves.any(
        (s) => s.text == 'Barcelona' && s.style?.fontWeight == FontWeight.w600,
      ),
      isTrue,
    );
  });

  test(
    'Keeps unclosed markers, multiplication asterisks and plain text literal',
    () {
      expect(assistantMarkdownPlainText('**sense tancar'), '**sense tancar');
      expect(
        assistantMarkdownPlainText('Horari: 2 * 3 * 4'),
        'Horari: 2 * 3 * 4',
      );
      expect(
        assistantMarkdownPlainText('Text normal sense format.'),
        'Text normal sense format.',
      );
      expect(assistantMarkdownPlainText(''), '');
    },
  );

  testWidgets('AssistantMessageBubble renders bold in assistant replies only', (
    tester,
  ) async {
    final assistantMsg = AssistantMessage.assistant(
      id: 'a1',
      text:
          'Aquí tens 2 propostes:\n- **Les parets criden**\n- **Clave Gaudí**',
      sentAt: DateTime(2026, 11, 21, 12),
    );
    final userMsg = AssistantMessage.user(
      id: 'u1',
      text: 'Busco **concerts** a Girona',
      sentAt: DateTime(2026, 11, 21, 11),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ListView(
            children: [
              AssistantMessageBubble(
                message: userMsg,
                onActivitySelected: (_) {},
              ),
              AssistantMessageBubble(
                message: assistantMsg,
                onActivitySelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    // User bubble preserves literal asterisks.
    expect(find.text('Busco **concerts** a Girona'), findsOneWidget);

    // Assistant bubble strips asterisks and renders bold spans.
    expect(
      find.text('Aquí tens 2 propostes:\n• Les parets criden\n• Clave Gaudí'),
      findsOneWidget,
    );
    expect(find.textContaining('**Les parets criden**'), findsNothing);

    final richText = tester.widget<Text>(
      find.descendant(
        of: find.byType(AssistantMarkdownText),
        matching: find.byType(Text),
      ),
    );
    final boldTexts = _leafSpans(richText.textSpan!)
        .where((s) => s.style?.fontWeight == FontWeight.bold)
        .map((s) => s.text);
    expect(boldTexts, ['Les parets criden', 'Clave Gaudí']);
  });

  testWidgets(
    'Markdown assistant bubble survives 320px width and 2.0x text scale',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final msg = AssistantMessage.assistant(
        id: 'a-scale',
        text:
            'He entès: exposicions a Barcelona.\n'
            '- **Les parets criden**: art urbà contemporani.\n'
            '- **Clave Gaudí**: visita al modernisme.',
        sentAt: DateTime(2026, 11, 21, 12),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AssistantMessageBubble(
                message: msg,
                onActivitySelected: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Les parets criden'), findsOneWidget);
      expect(find.textContaining('**'), findsNothing);
    },
  );
}
