import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/formatters/reliability_formatter.dart';
import '../../../../core/links/open_external_link.dart';
import '../../models/activity.dart';
import '../../repositories/activity_details_repository.dart';
import '../formatters/activity_date_formatter.dart';
import '../formatters/activity_modality_formatter.dart';
import '../formatters/activity_price_formatter.dart';
import '../view_models/activity_details_view_model.dart';
import '../view_models/enrollment_view_model.dart';
import '../widgets/activity_badges.dart';
import '../widgets/activity_information_row.dart';
import '../widgets/activity_image.dart';
import '../widgets/enrollment_action.dart';
import '../widgets/enrollment_badge.dart';

class ActivityDetailsScreen extends StatefulWidget {
  const ActivityDetailsScreen({
    super.key,
    required this.activityId,
    required this.repository,
    required this.enrollmentViewModel,
    this.ratingBuilder,
    this.canEdit,
    this.onEdit,
    this.openLink = openExternalLink,
  });

  final String activityId;
  final ActivityDetailsRepository repository;
  final EnrollmentViewModel enrollmentViewModel;

  /// Rating block for the activity; the app decides when it can be rated.
  final Widget Function(Activity activity)? ratingBuilder;

  /// Si qui mira la fitxa pot editar l'activitat (n'és qui l'ha creada).
  final bool Function(Activity activity)? canEdit;

  /// Obre el formulari d'edició; acaba amb `true` si s'han desat canvis, i
  /// llavors la fitxa es torna a carregar.
  final Future<bool> Function(Activity activity)? onEdit;

  /// Obre un enllaç de l'activitat fora de l'app; `false` si no ha pogut.
  final Future<bool> Function(Uri uri) openLink;

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

  Future<void> _edit(Activity activity) async {
    final saved = await widget.onEdit?.call(activity) ?? false;
    if (saved && mounted) _viewModel.load();
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
        actions: [
          // Només per a qui l'ha creada, quan ja s'ha carregat.
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, child) {
              final activity = _viewModel.activity;
              if (activity == null ||
                  widget.onEdit == null ||
                  !(widget.canEdit?.call(activity) ?? false)) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Edita l’activitat',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(activity),
              );
            },
          ),
        ],
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
                Expanded(
                  child: _ActivityDetailsContent(
                    activity: activity,
                    enrollmentViewModel: widget.enrollmentViewModel,
                    ratingBuilder: widget.ratingBuilder,
                    openLink: widget.openLink,
                  ),
                ),
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
  const _ActivityDetailsContent({
    required this.activity,
    required this.enrollmentViewModel,
    this.ratingBuilder,
    required this.openLink,
  });

  final Activity activity;
  final EnrollmentViewModel enrollmentViewModel;
  final Widget Function(Activity activity)? ratingBuilder;
  final Future<bool> Function(Uri uri) openLink;

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
          child: ActivityImage(
            activity: activity,
            height: 168,
            width: double.infinity,
            semanticLabel: activity.title,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final category in activity.categories)
              ActivityCategoryBadge(category: category),
            EnrollmentStatusBadge(
              viewModel: enrollmentViewModel,
              activityId: activity.id,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          activity.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (ratingBuilder != null) ratingBuilder!(activity),
        const SizedBox(height: 16),
        ActivityInformationRow(
          icon: Icons.calendar_month_outlined,
          text: formatActivityWhen(activity, includeDate: true),
        ),
        if (activity.endsAt case final endsAt?) ...[
          const SizedBox(height: 10),
          ActivityInformationRow(
            icon: Icons.event_available_outlined,
            text: 'Fins al ${_lowerFirst(formatActivityDate(endsAt))}',
          ),
        ],
        if (activity.isPermanent) ...[
          const SizedBox(height: 10),
          const ActivityInformationRow(
            icon: Icons.all_inclusive,
            text: 'Activitat permanent',
          ),
        ],
        // El municipi és opcional a les activitats no oficials.
        if (activity.municipality.isNotEmpty) ...[
          const SizedBox(height: 10),
          ActivityInformationRow(
            icon: Icons.location_on_outlined,
            text: activity.municipality,
          ),
        ],
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
        if (activity.modality case final modality?) ...[
          const SizedBox(height: 10),
          ActivityInformationRow(
            icon: switch (modality) {
              ActivityModality.inPerson => Icons.groups_outlined,
              ActivityModality.online => Icons.videocam_outlined,
              ActivityModality.mixed => Icons.devices_outlined,
            },
            text: activityModalityLabel(modality),
          ),
        ],
        if (activity.tickets case final tickets?) ...[
          const SizedBox(height: 10),
          ActivityInformationRow(
            icon: Icons.confirmation_number_outlined,
            text: tickets,
          ),
        ],
        if (activity.email case final email?) ...[
          const SizedBox(height: 10),
          ActivityInformationRow(icon: Icons.mail_outline, text: email),
        ],
        if (activity.phone case final phone?) ...[
          const SizedBox(height: 10),
          ActivityInformationRow(icon: Icons.phone_outlined, text: phone),
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
        if (_linksOf(activity) case final links when links.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Enllaços',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (final link in links)
            _ActivityLinkRow(link: link, openLink: openLink),
        ],
        if (activity.source == ActivitySource.culturalAgenda) ...[
          const SizedBox(height: 20),
          Text(
            'Font: Agenda Cultural · Generalitat',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
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

String _lowerFirst(String text) =>
    text.isEmpty ? text : text[0].toLowerCase() + text.substring(1);

/// Tots els enllaços de l'activitat, sense repetir cap adreça.
List<ActivityLink> _linksOf(Activity activity) {
  final links = [
    if (activity.onlineUrl case final url?)
      ActivityLink(name: 'Enllaç per connectar-s’hi', url: url),
    if (activity.website case final url?)
      ActivityLink(name: 'Web de l’activitat', url: url),
    if (activity.ticketsUrl case final url?)
      ActivityLink(name: 'Entrades', url: url),
    ...activity.links,
  ];
  final seen = <String>{};
  return [
    for (final link in links)
      if (seen.add(link.url)) link,
  ];
}

/// Un enllaç amb el nom i l'adreça. Tocar-lo l'obre fora de l'app (DP-054);
/// el botó del costat el copia.
class _ActivityLinkRow extends StatelessWidget {
  const _ActivityLinkRow({required this.link, required this.openLink});

  final ActivityLink link;
  final Future<bool> Function(Uri uri) openLink;

  Future<void> _open(BuildContext context) async {
    final opened = await openLink(Uri.parse(link.url));
    if (opened || !context.mounted) return;
    _showMessage(context, 'No s’ha pogut obrir l’enllaç.');
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: link.url));
    if (!context.mounted) return;
    _showMessage(context, 'Enllaç copiat.');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Semantics(
            link: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _open(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            link.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Copia l’enllaç: ${link.name}',
          icon: const Icon(Icons.copy_outlined),
          onPressed: () => _copy(context),
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
                Semantics(
                  label: creator.reliability == null
                      ? 'Fiabilitat de l’organitzador: sense valoracions'
                      : 'Fiabilitat de l’organitzador: '
                            '${formatReliability(creator.reliability)} sobre 5',
                  excludeSemantics: true,
                  child: Text.rich(
                    TextSpan(
                      text:
                          'Fiabilitat ${formatReliability(creator.reliability)}',
                      children: [
                        if (creator.reliability != null)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.star,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
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
