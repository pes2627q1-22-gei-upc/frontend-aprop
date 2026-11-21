import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/formatters/reliability_formatter.dart';
import '../../../../core/l10n/date_labels.dart';
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
import '../../../../core/l10n/locale_controller.dart';
import '../../../../l10n/app_localizations.dart';

class ActivityDetailsScreen extends StatefulWidget {
  const ActivityDetailsScreen({
    super.key,
    required this.activityId,
    required this.repository,
    required this.enrollmentViewModel,
    this.ratingBuilder,
    this.canEdit,
    this.onEdit,
    this.onCancel,
    this.onOpenChat,
    this.onCreatorSelected,
    this.openLink = openExternalLink,
  });

  final String activityId;

  /// Obre el xat de l'activitat. Només s'hi pot entrar si s'hi està apuntat
  /// (R11); sense, el botó queda desactivat.
  final void Function(Activity activity)? onOpenChat;
  final ActivityDetailsRepository repository;
  final EnrollmentViewModel enrollmentViewModel;

  /// Rating block for the activity; the app decides when it can be rated.
  final Widget Function(Activity activity)? ratingBuilder;

  /// Si qui mira la fitxa pot editar l'activitat (n'és qui l'ha creada).
  final bool Function(Activity activity)? canEdit;

  /// Obre el formulari d'edició; acaba amb `true` si s'han desat canvis, i
  /// llavors la fitxa es torna a carregar.
  final Future<bool> Function(Activity activity)? onEdit;

  /// Cancel·la l'activitat (#46), un cop confirmat al diàleg; acaba amb
  /// `true` si s'ha cancel·lat. Només surt per a qui la pot editar.
  final Future<bool> Function(Activity activity)? onCancel;

  /// Obre el perfil de qui ha creat l'activitat (rep el seu ID). Sense,
  /// «Veure perfil» queda desactivat.
  final ValueChanged<String>? onCreatorSelected;

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

  bool _isCancelling = false;

  /// Pregunta abans de cancel·lar: no es pot desfer i avisa les persones
  /// apuntades (CA1).
  Future<void> _cancel(Activity activity) async {
    final cancel = widget.onCancel;
    if (cancel == null || _isCancelling) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.activityCancelTitle),
        content: Text(context.l10n.activityCancelBody(activity.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.activityCancelKeep),
          ),
          FilledButton(
            key: const ValueKey('activity-cancel-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.activityCancelConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isCancelling = true);
    try {
      await cancel(activity);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
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
        title: Text(context.l10n.actDetailsTitle),
        centerTitle: true,
        leading: IconButton(
          tooltip: context.l10n.goBack,
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
                tooltip: context.l10n.actEdit,
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
              return _DetailsMessage(
                icon: Icons.event_busy_outlined,
                title: context.l10n.actNotFound,
              );
            }

            return Column(
              children: [
                Expanded(
                  child: _ActivityDetailsContent(
                    activity: activity,
                    enrollmentViewModel: widget.enrollmentViewModel,
                    ratingBuilder: widget.ratingBuilder,
                    onOpenChat: widget.onOpenChat,
                    openLink: widget.openLink,
                    onCreatorSelected: widget.onCreatorSelected,
                    isCancelling: _isCancelling,
                    onCancel:
                        widget.onCancel != null &&
                            (widget.canEdit?.call(activity) ?? false)
                        ? () => _cancel(activity)
                        : null,
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
    this.onOpenChat,
    required this.openLink,
    this.onCreatorSelected,
    this.onCancel,
    this.isCancelling = false,
  });

  final Activity activity;
  final EnrollmentViewModel enrollmentViewModel;
  final Widget Function(Activity activity)? ratingBuilder;
  final void Function(Activity activity)? onOpenChat;
  final Future<bool> Function(Uri uri) openLink;
  final ValueChanged<String>? onCreatorSelected;

  /// «Cancel·lar l'activitat»; nul si qui mira no la pot cancel·lar.
  final VoidCallback? onCancel;
  final bool isCancelling;

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
            text: context.l10n.actUntil(dateWithYear(endsAt)),
          ),
        ],
        if (activity.isPermanent) ...[
          const SizedBox(height: 10),
          ActivityInformationRow(
            icon: Icons.all_inclusive,
            text: context.l10n.actPermanent,
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
          _CreatorSection(
            creator: creator,
            onViewProfile: switch ((creator.userId, onCreatorSelected)) {
              (final id?, final open?) => () => open(id),
              _ => null,
            },
          ),
        ],
        const SizedBox(height: 20),
        Text(
          context.l10n.actAbout,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description == null || description.isEmpty
              ? context.l10n.actNoDescription
              : description,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        if (_linksOf(activity, context.l10n) case final links
            when links.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            context.l10n.actLinks,
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
            context.l10n.agendaSourceOfficial,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Només qui s'hi ha apuntat pot fer servir el xat (R11).
        ListenableBuilder(
          listenable: enrollmentViewModel,
          builder: (context, child) {
            final openChat = onOpenChat;
            final canChat =
                openChat != null && enrollmentViewModel.isEnrolled(activity.id);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: canChat ? () => openChat(activity) : null,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(context.l10n.actChat),
                ),
                const SizedBox(height: 8),
                Text(
                  canChat
                      ? context.l10n.actChatHint
                      : context.l10n.actChatNeedsEnrollment,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
        // Qui l'ha creada la pot cancel·lar abans que comenci (#46).
        if (onCancel case final cancel?)
          ListenableBuilder(
            listenable: enrollmentViewModel,
            builder: (context, child) {
              if (enrollmentViewModel.isCancelled(activity.id)) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: OutlinedButton.icon(
                  key: const ValueKey('activity-cancel'),
                  onPressed: isCancelling ? null : cancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error),
                  ),
                  icon: isCancelling
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.error,
                          ),
                        )
                      : const Icon(Icons.event_busy_outlined),
                  label: Text(
                    isCancelling
                        ? context.l10n.activityCancelling
                        : context.l10n.activityCancel,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Tots els enllaços de l'activitat, sense repetir cap adreça.
List<ActivityLink> _linksOf(Activity activity, AppLocalizations l10n) {
  final links = [
    if (activity.onlineUrl case final url?)
      ActivityLink(name: l10n.actLinkJoin, url: url),
    if (activity.website case final url?)
      ActivityLink(name: l10n.actLinkWebsite, url: url),
    if (activity.ticketsUrl case final url?)
      ActivityLink(name: l10n.actLinkAccess, url: url),
    ...activity.links,
  ];
  final seen = <String>{};
  return [
    for (final link in links)
      if (seen.add(link.url)) link,
  ];
}

/// Un enllaç amb el nom i l'adreça. Tocar-lo l'obre fora de l'app (DP-058);
/// el botó del costat el copia.
class _ActivityLinkRow extends StatelessWidget {
  const _ActivityLinkRow({required this.link, required this.openLink});

  final ActivityLink link;
  final Future<bool> Function(Uri uri) openLink;

  Future<void> _open(BuildContext context) async {
    // El mapper ja només deixa passar adreces http(s); per si de cas.
    final uri = Uri.tryParse(link.url);
    final valid =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    final opened = valid && await openLink(uri);
    if (opened || !context.mounted) return;
    _showMessage(context, context.l10n.actLinkOpenError);
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: link.url));
    if (!context.mounted) return;
    _showMessage(context, context.l10n.actLinkCopied);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
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
          tooltip: context.l10n.actLinkCopy(link.name),
          icon: const Icon(Icons.copy_outlined),
          onPressed: () => _copy(context),
        ),
      ],
    );
  }
}

class _CreatorSection extends StatelessWidget {
  const _CreatorSection({required this.creator, this.onViewProfile});

  final ActivityCreator creator;
  final VoidCallback? onViewProfile;

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
                      Text(context.l10n.actPublishedBy),
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
                      ? context.l10n.actReliabilityNone
                      : context.l10n.actReliabilityOutOfFive(
                          formatReliability(creator.reliability),
                        ),
                  excludeSemantics: true,
                  child: Text.rich(
                    TextSpan(
                      text: context.l10n.actReliabilityChip(
                        formatReliability(creator.reliability),
                      ),
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
                if (onViewProfile == null)
                  Tooltip(
                    message: context.l10n.notifProfileSoon,
                    child: TextButton.icon(
                      onPressed: null,
                      label: Text(context.l10n.actViewProfile),
                      icon: const Icon(Icons.chevron_right, size: 20),
                    ),
                  )
                else
                  TextButton.icon(
                    key: const ValueKey('activity-creator-profile'),
                    onPressed: onViewProfile,
                    label: Text(context.l10n.actViewProfile),
                    icon: const Icon(Icons.chevron_right, size: 20),
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
              FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
            ],
          ],
        ),
      ),
    );
  }
}
