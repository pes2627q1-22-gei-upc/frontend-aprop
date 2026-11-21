import 'package:flutter/material.dart';

import '../../../../core/widgets/content_image.dart';
import '../../models/interest_question.dart';
import '../../repositories/interest_test_repository.dart';
import '../view_models/interest_test_view_model.dart';
import '../../../../core/l10n/locale_controller.dart';

/// Shows the test activities one by one: swipe right if it interests the
/// user, left if it does not. Buttons offer the same choice without swiping.
class InterestTestScreen extends StatefulWidget {
  const InterestTestScreen({
    super.key,
    required this.repository,
    this.onBack,
    this.onSkip,
    this.onDone,
    this.onCompleted,
  }) : assert(
         onBack != null || onSkip != null || onDone != null,
         'Provide onBack, onSkip or onDone',
       );

  final InterestTestRepository repository;

  /// Back button action when opened from Settings or Assistant.
  final VoidCallback? onBack;

  /// «Ara no» action shown during onboarding while the test is not completed.
  final VoidCallback? onSkip;

  /// Action for the final completion / empty-state button; defaults to
  /// [onBack] or [onSkip].
  final VoidCallback? onDone;

  /// Notified once answers are saved successfully.
  final VoidCallback? onCompleted;

  @override
  State<InterestTestScreen> createState() => _InterestTestScreenState();
}

class _InterestTestScreenState extends State<InterestTestScreen> {
  late InterestTestViewModel _viewModel;
  bool _notifiedCompleted = false;

  void _createViewModel() {
    _notifiedCompleted = false;
    final viewModel = InterestTestViewModel(repository: widget.repository);
    _viewModel = viewModel;
    viewModel
      ..addListener(_onModelChanged)
      ..load();
  }

  void _onModelChanged() {
    if (!_notifiedCompleted && _viewModel.isCompleted) {
      _notifiedCompleted = true;
      widget.onCompleted?.call();
    }
  }

  @override
  void initState() {
    super.initState();
    _createViewModel();
  }

  @override
  void didUpdateWidget(covariant InterestTestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _viewModel.removeListener(_onModelChanged);
      _viewModel.dispose();
      _createViewModel();
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  VoidCallback get _finish => widget.onDone ?? widget.onBack ?? widget.onSkip!;
  bool get _isOnboarding => widget.onBack == null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.interestTestTitle),
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: widget.onBack == null
          ? null
          : IconButton(
              tooltip: context.l10n.goBack,
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
            ),
      actions: [
        if (widget.onSkip case final onSkip?)
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) =>
                _viewModel.isCompleted || _viewModel.isSubmitting
                ? const SizedBox.shrink()
                : TextButton(
                    key: const ValueKey('interest-test-skip'),
                    onPressed: onSkip,
                    child: Text(context.l10n.interestTestSkip),
                  ),
          ),
      ],
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
      return Center(
        child: CircularProgressIndicator(
          semanticsLabel: context.l10n.interestTestLoading,
        ),
      );
    }
    if (model.errorMessage case final error?) {
      return _Message(
        text: error,
        action: context.l10n.retry,
        onPressed: model.load,
      );
    }
    if (model.questions.isEmpty) {
      return _Message(
        text: context.l10n.interestTestEmpty,
        action: _isOnboarding
            ? context.l10n.interestTestContinue
            : context.l10n.interestTestBack,
        onPressed: _finish,
      );
    }
    if (model.isCompleted) {
      return _Message(
        text: context.l10n.interestTestDone,
        action: _isOnboarding
            ? context.l10n.interestTestContinue
            : context.l10n.interestTestBackToSettings,
        onPressed: _finish,
      );
    }
    final question = model.current;
    if (question == null) {
      if (model.submitError case final error?) {
        return _Message(
          text: error,
          action: context.l10n.retry,
          onPressed: model.submit,
        );
      }
      return Center(
        child: CircularProgressIndicator(
          semanticsLabel: context.l10n.interestTestSaving,
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.interestTestProgress(
            model.answeredCount + 1,
            model.questions.length,
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: model.answeredCount / model.questions.length,
          semanticsLabel: context.l10n.interestTestProgressSemantics,
        ),
        const SizedBox(height: 8),
        Text(context.l10n.interestTestSwipeHint, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Expanded(
          child: Dismissible(
            key: ValueKey(question.eventId),
            // TODO(DP-042): A like only records the interest; it does not enrol.
            onDismissed: (direction) =>
                model.answer(likes: direction == DismissDirection.startToEnd),
            background: _SwipeHint(
              icon: Icons.favorite,
              label: context.l10n.interestTestLike,
              color: colors.primary,
              alignment: Alignment.centerLeft,
            ),
            secondaryBackground: _SwipeHint(
              icon: Icons.close,
              label: context.l10n.interestTestDislike,
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
                label: Text(context.l10n.interestTestDislike),
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
                label: Text(context.l10n.interestTestLike),
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
                    Text(
                      question.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
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
