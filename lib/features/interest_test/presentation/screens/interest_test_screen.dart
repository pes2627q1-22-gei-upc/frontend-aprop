import 'package:flutter/material.dart';

import '../../../../core/widgets/content_image.dart';
import '../../models/interest_question.dart';
import '../../repositories/interest_test_repository.dart';
import '../view_models/interest_test_view_model.dart';

/// Shows the test activities one by one: swipe right if it interests the
/// user, left if it does not. Buttons offer the same choice without swiping.
class InterestTestScreen extends StatefulWidget {
  const InterestTestScreen({
    super.key,
    required this.repository,
    required this.onBack,
  });
  final InterestTestRepository repository;
  final VoidCallback onBack;

  @override
  State<InterestTestScreen> createState() => _InterestTestScreenState();
}

class _InterestTestScreenState extends State<InterestTestScreen> {
  late final _viewModel = InterestTestViewModel(repository: widget.repository)
    ..load();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Test d’interessos'),
      centerTitle: true,
      leading: IconButton(
        tooltip: 'Tornar enrere',
        onPressed: widget.onBack,
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => _body(context, _viewModel),
        ),
      ),
    ),
  );

  Widget _body(BuildContext context, InterestTestViewModel model) {
    if (model.isLoading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Carregant el test'),
      );
    }
    if (model.errorMessage case final error?) {
      return _Message(
        text: error,
        action: 'Tornar-ho a provar',
        onPressed: model.load,
      );
    }
    if (model.questions.isEmpty) {
      return _Message(
        text: 'Ara mateix no hi ha activitats per al test.',
        action: 'Tornar',
        onPressed: widget.onBack,
      );
    }
    if (model.isCompleted) {
      return _Message(
        text: 'Hem actualitzat els teus interessos. Les recomanacions de «Per a tu» els tindran en compte.',
        action: 'Tornar a la configuració',
        onPressed: widget.onBack,
      );
    }
    final question = model.current;
    if (question == null) {
      if (model.submitError case final error?) {
        return _Message(
          text: error,
          action: 'Tornar-ho a provar',
          onPressed: model.submit,
        );
      }
      return const Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Desant les respostes',
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${model.answeredCount + 1} de ${model.questions.length}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: model.answeredCount / model.questions.length,
          semanticsLabel: 'Progrés del test',
        ),
        const SizedBox(height: 8),
        const Text(
          'Llisca cap a la dreta si t’interessa i cap a l’esquerra si no.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Dismissible(
            key: ValueKey(question.eventId),
            // TODO(DP-042): A like only records the interest; it does not enrol.
            onDismissed: (direction) =>
                model.answer(likes: direction == DismissDirection.startToEnd),
            background: _SwipeHint(
              icon: Icons.favorite,
              label: 'M’interessa',
              color: colors.primary,
              alignment: Alignment.centerLeft,
            ),
            secondaryBackground: _SwipeHint(
              icon: Icons.close,
              label: 'No m’interessa',
              color: colors.error,
              alignment: Alignment.centerRight,
            ),
            child: _QuestionCard(question: question),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('interest-test-dislike'),
                onPressed: () => model.answer(likes: false),
                icon: const Icon(Icons.close),
                label: const Text('No m’interessa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('interest-test-like'),
                onPressed: () => model.answer(likes: true),
                icon: const Icon(Icons.favorite),
                label: const Text('M’interessa'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});
  final InterestQuestion question;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ContentImage(
              url: question.imageUrl,
              asset: question.imageAsset,
              label: question.title,
              excludeFromSemantics: true,
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question.title, style: textTheme.titleLarge),
                  if (question.categories.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final category in question.categories)
                          Chip(label: Text(category)),
                      ],
                    ),
                  ],
                  if (question.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(question.description),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.icon,
    required this.label,
    required this.color,
    required this.alignment,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 40),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.action,
    required this.onPressed,
  });
  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(text, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );
}
