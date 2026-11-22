import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/widgets/content_image.dart';
import '../../../activities/models/activity_category_labels.dart';
import '../../models/interest_question.dart';
import '../../repositories/interest_test_repository.dart';
import '../view_models/interest_test_view_model.dart';

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
    this.initialAnsweredCount,
  }) : assert(
         onBack != null || onSkip != null || onDone != null,
         'Provide onBack, onSkip or onDone',
       );

  final InterestTestRepository repository;

  /// Back button action when opened from Settings or Assistant.
  final VoidCallback? onBack;

  /// «Més tard» action that saves any partial progress before leaving.
  final VoidCallback? onSkip;

  /// Action for the final completion / empty-state button; defaults to
  /// [onBack] or [onSkip].
  final VoidCallback? onDone;

  /// Notified once answers are saved successfully.
  final VoidCallback? onCompleted;

  /// Previously answered count when already fetched by the caller.
  final int? initialAnsweredCount;

  @override
  State<InterestTestScreen> createState() => _InterestTestScreenState();
}

class _InterestTestScreenState extends State<InterestTestScreen> {
  late InterestTestViewModel _viewModel;
  bool _notifiedCompleted = false;

  void _createViewModel() {
    _notifiedCompleted = false;
    final viewModel = InterestTestViewModel(
      repository: widget.repository,
      initialAnsweredCount: widget.initialAnsweredCount,
    );
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

  Future<void> _handlePauseAndExit(VoidCallback exit) async {
    if (!_viewModel.hasUnsavedAnswers) {
      exit();
      return;
    }
    final saved = await _viewModel.savePartialProgress();
    if (!mounted) return;
    if (saved) {
      exit();
      return;
    }
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.partialSaveError ?? context.l10n.interestTestSaveError,
          ),
          action: SnackBarAction(
            label: context.l10n.interestTestLeaveWithoutSaving,
            onPressed: exit,
          ),
        ),
      );
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    // System back must also save the answers so far (like «Més tard»).
    builder: (context, child) => PopScope(
      canPop: widget.onBack == null || !_viewModel.hasUnsavedAnswers,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_viewModel.isSavingPartial) {
          _handlePauseAndExit(widget.onBack!);
        }
      },
      child: child!,
    ),
    child: _buildScaffold(context),
  );

  Widget _buildScaffold(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.interestTestTitle),
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: widget.onBack == null
          ? null
          : ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => IconButton(
                tooltip: context.l10n.goBack,
                onPressed: _viewModel.isSubmitting || _viewModel.isSavingPartial
                    ? null
                    : () => _handlePauseAndExit(widget.onBack!),
                icon: const Icon(Icons.arrow_back),
              ),
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
                    onPressed: _viewModel.isSavingPartial
                        ? null
                        : () => _handlePauseAndExit(onSkip),
                    child: _viewModel.isSavingPartial
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.interestTestSkip),
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
    final total = model.totalCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.interestTestProgress(model.answeredCount + 1, total),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: total > 0 ? model.answeredCount / total : 0,
          semanticsLabel: context.l10n.interestTestProgressSemantics,
        ),
        const SizedBox(height: 8),
        Text(context.l10n.interestTestSwipeHint, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Expanded(
          child: Dismissible(
            key: ValueKey(question.eventId),
            direction: model.isSavingPartial
                ? DismissDirection.none
                : DismissDirection.horizontal,
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
                onPressed: model.isSavingPartial
                    ? null
                    : () => model.answer(likes: false),
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
                onPressed: model.isSavingPartial
                    ? null
                    : () => model.answer(likes: true),
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

  static const double _imageAspectRatio = 16 / 9;
  static const double _minImageHeight = 96;
  static const double _maxImageHeight = 196;
  static const double _maxImageFraction = 0.38;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight.isFinite
              ? (constraints.maxHeight * _maxImageFraction).clamp(
                  _minImageHeight,
                  _maxImageHeight,
                )
              : _maxImageHeight;
          final imageHeight = constraints.maxWidth.isFinite
              ? (constraints.maxWidth / _imageAspectRatio).clamp(
                  _minImageHeight,
                  maxHeight,
                )
              : maxHeight;
          final cacheWidth =
              constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? (constraints.maxWidth * dpr).round()
              : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TODO(DP-080): Fixed 16:9 capped banner with allowUpscaling: false
              // and FilterQuality.high avoids pixelating smaller Gencat covers
              // while leaving most of the card height for title and description.
              SizedBox(
                key: const ValueKey('interest-test-card-image'),
                height: imageHeight,
                width: double.infinity,
                child: ContentImage(
                  url: question.imageUrl,
                  asset: question.imageAsset,
                  label: question.title,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  cacheWidth: cacheWidth,
                  excludeFromSemantics: true,
                ),
              ),
              Expanded(
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
                              Chip(
                                label: Text(
                                  localizeActivityCategory(
                                    category,
                                    languageCode: context.l10n.localeName,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (question.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _ExpandableDescription(text: question.description),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.text});
  final String text;

  static const int collapsedMaxLines = 5;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _ExpandableDescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _ExpandableDescription.collapsedMaxLines,
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout(maxWidth: constraints.maxWidth);
        final exceeds = painter.didExceedMaxLines;
        painter.dispose();

        if (!exceeds) {
          return Text(widget.text, style: style);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _expanded
                  ? null
                  : _ExpandableDescription.collapsedMaxLines,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: style,
            ),
            const SizedBox(height: 4),
            TextButton(
              key: const ValueKey('interest-test-read-more'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? context.l10n.interestTestReadLess
                    : context.l10n.interestTestReadMore,
              ),
            ),
          ],
        );
      },
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
