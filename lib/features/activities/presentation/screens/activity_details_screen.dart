import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../repositories/activity_repository.dart';
import '../formatters/activity_date_formatter.dart';
import '../formatters/activity_price_formatter.dart';
import '../view_models/activity_details_view_model.dart';
import '../view_models/enrollment_view_model.dart';
import '../widgets/activity_badges.dart';
import '../widgets/activity_information_row.dart';
import '../widgets/enrollment_action.dart';

class ActivityDetailsScreen extends StatefulWidget {
  const ActivityDetailsScreen({
    super.key,
    required this.activityId,
    required this.repository,
    required this.enrollmentViewModel,
  });

  final String activityId;
  final ActivityRepository repository;
  final EnrollmentViewModel enrollmentViewModel;

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  late ActivityDetailsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _createViewModel();
  }

  void _createViewModel() {
    _viewModel = ActivityDetailsViewModel(
      activityId: widget.activityId,
      repository: widget.repository,
    );
    _viewModel.load();
  }

  @override
  void didUpdateWidget(covariant ActivityDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activityId != widget.activityId ||
        oldWidget.repository != widget.repository) {
      _viewModel.dispose();
      _createViewModel();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activitat'),
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
          listenable: _viewModel,
          builder: (context, child) {
            if (_viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final errorMessage = _viewModel.errorMessage;
            if (errorMessage != null) {
              return _DetailsMessage(
                icon: Icons.cloud_off_outlined,
                title: errorMessage,
                onRetry: _viewModel.load,
              );
            }

            final activity = _viewModel.activity;
            if (activity == null) {
              return const _DetailsMessage(
                icon: Icons.event_busy_outlined,
                title: 'No hem trobat aquesta activitat.',
              );
            }

            return Column(
              children: [
                Expanded(child: _ActivityDetailsContent(activity: activity)),
                _ParticipationAction(
                  activity: activity,
                  viewModel: widget.enrollmentViewModel,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActivityDetailsContent extends StatelessWidget {
  const _ActivityDetailsContent({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final creator = activity.creator;
    final description = activity.description?.trim();

    return ListView(
      key: PageStorageKey<String>('activity-details-${activity.id}'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            activity.imageAsset,
            height: 168,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: activity.title,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: colors.surfaceContainerHighest,
              child: const SizedBox(
                height: 168,
                child: Center(child: Icon(Icons.image_outlined, size: 48)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ActivityCategoryBadge(category: activity.category),
        ),
        const SizedBox(height: 8),
        Text(
          activity.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ActivityInformationRow(
          icon: Icons.calendar_month_outlined,
          text: formatActivitySchedule(activity.startsAt, includeDate: true),
        ),
        const SizedBox(height: 10),
        ActivityInformationRow(
          icon: Icons.location_on_outlined,
          text: activity.municipality,
        ),
        if (activity.directions case final directions?) ...[
          const SizedBox(height: 10),
          ActivityInformationRow(
            icon: Icons.signpost_outlined,
            text: directions,
          ),
        ],
        if (activity.price case final price?) ...[
          const SizedBox(height: 10),
          ActivityInformationRow(
            icon: Icons.sell_outlined,
            text: formatActivityPrice(price),
          ),
        ],
        if (activity.source == ActivitySource.community && creator != null) ...[
          const SizedBox(height: 16),
          _CreatorSection(creator: creator),
        ],
        const SizedBox(height: 20),
        Text(
          'Sobre l’activitat',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description == null || description.isEmpty
              ? 'Encara no hi ha una descripció disponible.'
              : description,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        if (activity.source == ActivitySource.culturalAgenda) ...[
          const SizedBox(height: 20),
          Text(
            'Informació pràctica',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Font: Agenda Cultural · Generalitat'),
          Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: 'Enllaç original disponible properament',
              child: TextButton.icon(
                onPressed: null,
                icon: const Icon(Icons.open_in_new, size: 20),
                label: const Text('Consultar informació original'),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Tooltip(
          message: 'Xat disponible properament',
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Xat de l’activitat'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Parla amb les persones que també s’hi han apuntat.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CreatorSection extends StatelessWidget {
  const _CreatorSection({required this.creator});

  final ActivityCreator creator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  // Sense foto (qui crea una activitat no en té) es mostra la
                  // mateixa icona que si la foto no es pot carregar.
                  child: switch (creator.avatarAsset) {
                    final avatar? => Image.asset(
                      avatar,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _CreatorAvatarPlaceholder(),
                    ),
                    null => const _CreatorAvatarPlaceholder(),
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Publicat per'),
                      Text(creator.name, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (creator.isFriend) const FriendshipBadge(),
                Tooltip(
                  message: 'Perfil disponible properament',
                  child: TextButton.icon(
                    onPressed: null,
                    label: const Text('Veure perfil'),
                    icon: const Icon(Icons.chevron_right, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipationAction extends StatelessWidget {
  const _ParticipationAction({required this.activity, required this.viewModel});

  final Activity activity;
  final EnrollmentViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: EnrollmentAction(
          viewModel: viewModel,
          activityId: activity.id,
          activityTitle: activity.title,
          primary: true,
          showHelper: true,
        ),
      ),
    );
  }
}

class _CreatorAvatarPlaceholder extends StatelessWidget {
  const _CreatorAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 44,
      height: 44,
      child: Icon(Icons.person_outline),
    );
  }
}

class _DetailsMessage extends StatelessWidget {
  const _DetailsMessage({
    required this.icon,
    required this.title,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tornar-ho a provar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
