import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../models/activity.dart';
import '../../models/activity_category.dart';
import '../../models/activity_category_labels.dart';
import '../../models/activity_options.dart';
import '../../repositories/activity_category_repository.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/location_repository.dart';
import '../formatters/activity_date_formatter.dart';
import '../view_models/create_activity_view_model.dart';
import '../widgets/activity_badges.dart';
import '../widgets/location_picker_map.dart';
import '../widgets/start_date_time_sheet.dart';

/// Formulari per publicar una activitat no oficial (Taiga #31).
// TODO(DP-021): disseny sense mockup aprovat, pendent de validar.

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({
    super.key,
    required this.repository,
    required this.locationRepository,
    required this.creator,
    required this.onCreated,
    this.categoryRepository,
    this.now = DateTime.now,
    this.activity,
  });

  final ActivityRepository repository;

  /// Categories del backend. Si és nul, es fa servir la llista provisional.
  final ActivityCategoryRepository? categoryRepository;
  final LocationRepository locationRepository;
  final ActivityCreator creator;

  /// Rep l'activitat publicada o desada. Qui obre la pantalla decideix què es
  /// mostra després (la fitxa de l'activitat).
  final ValueChanged<Activity> onCreated;

  /// L'activitat que s'edita. Si és nul, se'n crea una de nova.
  final Activity? activity;

  /// Rellotge per validar la data d'inici; les proves el fixen.
  final DateTime Function() now;

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  // En editar, els camps comencen amb el que ja tenia l'activitat.
  late final _titleController = TextEditingController(
    text: widget.activity?.title,
  );
  late final _descriptionController = TextEditingController(
    text: widget.activity?.description,
  );
  late final _municipalityController = TextEditingController(
    text: widget.activity?.municipality,
  );
  late final _directionsController = TextEditingController(
    text: widget.activity?.directions,
  );
  late final _scheduleNoteController = TextEditingController(
    text: _viewModel.initialScheduleNote,
  );
  late final _onlineUrlController = TextEditingController(
    text: widget.activity?.onlineUrl,
  );
  late final _priceController = TextEditingController(
    text: _priceText(widget.activity?.price),
  );
  late final CreateActivityViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CreateActivityViewModel(
      repository: widget.repository,
      locationRepository: widget.locationRepository,
      creator: widget.creator,
      categoryRepository: widget.categoryRepository,
      now: widget.now,
      editing: widget.activity,
    )..loadCategories();
  }

  /// Preu per al camp: buit si és gratuïta o no se sap, i amb coma decimal.
  static String _priceText(double? price) {
    if (price == null || price == 0) return '';
    return price == price.roundToDouble()
        ? '${price.round()}'
        : price.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _municipalityController.dispose();
    _directionsController.dispose();
    _priceController.dispose();
    _scheduleNoteController.dispose();
    _onlineUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickStartsAt() async {
    FocusScope.of(context).unfocus();
    final today = _viewModel.today;
    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    final startsAt = await showStartDateTimeSheet(
      context,
      // Per defecte, demà a les 19.00.
      initial:
          _viewModel.startsAt ??
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19),
      now: widget.now(),
    );
    if (startsAt != null) _viewModel.setStartsAt(startsAt);
  }

  Future<void> _pickEndsAt() async {
    final startsAt = _viewModel.startsAt;
    if (startsAt == null) return;
    FocusScope.of(context).unfocus();

    final endsAt = _viewModel.endsAt;
    final picked = await showEndDateTimeSheet(
      context,
      // Per defecte, dues hores després de l'inici.
      initial: endsAt != null && endsAt.isAfter(startsAt)
          ? endsAt
          : startsAt.add(const Duration(hours: 2)),
      startsAt: startsAt,
    );
    if (picked != null) _viewModel.setEndsAt(picked);
  }

  String _locationCaption() {
    if (_viewModel.location == null) {
      return context.l10n.createLocationEmpty;
    }
    if (_viewModel.isLocationApproximate) {
      return context.l10n.createLocationApproximate;
    }
    return context.l10n.createLocationMarked;
  }

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();

    final activity = await _viewModel.publish(
      title: _titleController.text,
      description: _descriptionController.text,
      municipality: _municipalityController.text,
      directions: _directionsController.text,
      price: _priceController.text,
      scheduleNote: _scheduleNoteController.text,
      onlineUrl: _onlineUrlController.text,
    );
    if (activity != null && mounted) widget.onCreated(activity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _viewModel.isEditing
              ? context.l10n.createTitleEdit
              : context.l10n.createTitleNew,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) {
            final errorMessage = _viewModel.errorMessage;
            final startsAt = _viewModel.startsAt;
            final endsAt = _viewModel.endsAt;

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                _CoverImage(
                  imageAsset: _viewModel.imageAsset,
                  onSelected: _viewModel.setImageAsset,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: maxActivityTitleLength,
                  onChanged: (_) =>
                      _viewModel.onFieldChanged(CreateActivityField.title),
                  decoration: InputDecoration(
                    labelText: context.l10n.createFieldTitle,
                    errorText: _viewModel.fieldError(CreateActivityField.title),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: maxActivityDescriptionLength,
                  onChanged: (_) => _viewModel.onFieldChanged(
                    CreateActivityField.description,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.createFieldDescription,
                    alignLabelWithHint: true,
                    errorText: _viewModel.fieldError(
                      CreateActivityField.description,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.createFieldCategories,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  context.l10n.createCategoriesHint(maxActivityCategories),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (_viewModel.isLoadingCategories)
                  SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: context.l10n.createCategoriesLoading,
                        ),
                      ),
                    ),
                  )
                else if (_viewModel.categoriesError case final error?)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          error,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _viewModel.loadCategories,
                        child: Text(context.l10n.retry),
                      ),
                    ],
                  )
                else
                  _CategorySelector(
                    categories: _viewModel.categories,
                    selected: _viewModel.selectedCategories,
                    onSelected: _viewModel.toggleCategory,
                  ),
                if (_viewModel.fieldError(CreateActivityField.category)
                    case final categoryError?) ...[
                  const SizedBox(height: 4),
                  Text(
                    categoryError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                InkWell(
                  onTap: _pickStartsAt,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.l10n.createFieldStart,
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                      errorText: _viewModel.fieldError(
                        CreateActivityField.startsAt,
                      ),
                    ),
                    child: Text(
                      startsAt == null
                          ? context.l10n.createPickStart
                          : formatActivitySchedule(startsAt, includeDate: true),
                      style: startsAt == null
                          ? TextStyle(color: colors.onSurfaceVariant)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: startsAt == null ? null : _pickEndsAt,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.l10n.createFieldEnd,
                      prefixIcon: const Icon(Icons.event_available_outlined),
                      suffixIcon: endsAt == null
                          ? null
                          : IconButton(
                              onPressed: () => _viewModel.setEndsAt(null),
                              tooltip: context.l10n.createRemoveEnd,
                              icon: const Icon(Icons.close),
                            ),
                      enabled: startsAt != null,
                      errorText: _viewModel.fieldError(
                        CreateActivityField.endsAt,
                      ),
                    ),
                    child: Text(
                      switch ((startsAt, endsAt)) {
                        (null, _) => context.l10n.createPickStartFirst,
                        (_, null) => context.l10n.createNoEnd,
                        (_, final endsAt?) => formatActivitySchedule(
                          endsAt,
                          includeDate: true,
                        ),
                      },
                      style: endsAt == null
                          ? TextStyle(color: colors.onSurfaceVariant)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _scheduleNoteController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: maxActivityScheduleNoteLength,
                  decoration: InputDecoration(
                    labelText: context.l10n.createScheduleNoteLabel,
                    prefixIcon: const Icon(Icons.schedule),
                    hintText: context.l10n.createScheduleNoteHint,
                    helperText: context.l10n.createScheduleNoteHelper,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _municipalityController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: _viewModel.locateMunicipality,
                  decoration: InputDecoration(
                    labelText: context.l10n.createFieldMunicipality,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _directionsController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  minLines: 1,
                  maxLines: 3,
                  maxLength: maxActivityDirectionsLength,
                  decoration: InputDecoration(
                    labelText: context.l10n.createFieldDirections,
                    prefixIcon: const Icon(Icons.signpost_outlined),
                    hintText: context.l10n.createDirectionsHint,
                  ),
                ),
                const SizedBox(height: 8),
                // TODO(DP-020): Google Maps triat per l'usuari; pendent que
                // l'equip ho confirmi i de la clau compartida (DP-004).
                LocationPickerMap(
                  location: _viewModel.location,
                  onChanged: _viewModel.setLocation,
                ),
                const SizedBox(height: 4),
                Text(
                  _locationCaption(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: (_) =>
                      _viewModel.onFieldChanged(CreateActivityField.price),
                  decoration: InputDecoration(
                    labelText: context.l10n.createFieldPrice,
                    prefixIcon: const Icon(Icons.sell_outlined),
                    suffixText: '€',
                    helperText: _viewModel.hasUnknownPrice
                        ? context.l10n.createPriceHelperUnknown
                        : context.l10n.createPriceHelper,
                    errorText: _viewModel.fieldError(CreateActivityField.price),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.createModality,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<ActivityModality>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ActivityModality.inPerson,
                      label: Text(context.l10n.modalityInPerson),
                    ),
                    ButtonSegment(
                      value: ActivityModality.online,
                      label: Text(context.l10n.modalityOnline),
                    ),
                    ButtonSegment(
                      value: ActivityModality.mixed,
                      label: Text(context.l10n.createModalityBoth),
                      tooltip: context.l10n.modalityMixed,
                    ),
                  ],
                  selected: {_viewModel.modality},
                  onSelectionChanged: (selection) =>
                      _viewModel.setModality(selection.single),
                ),
                if (_viewModel.modality != ActivityModality.inPerson) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _onlineUrlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    onChanged: (_) => _viewModel.onFieldChanged(
                      CreateActivityField.onlineUrl,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.createOnlineUrlLabel,
                      prefixIcon: const Icon(Icons.link),
                      hintText: 'https://',
                      errorText: _viewModel.fieldError(
                        CreateActivityField.onlineUrl,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.actPermanent),
                  subtitle: Text(context.l10n.createPermanentHint),
                  value: _viewModel.isPermanent,
                  onChanged: _viewModel.setPermanent,
                ),
                const SizedBox(height: 24),
                if (errorMessage != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: _viewModel.isPublishing ? null : _publish,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _viewModel.isPublishing
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            semanticsLabel: context.l10n.createPublishing,
                          ),
                        )
                      : Text(
                          _viewModel.isEditing
                              ? context.l10n.createSaveChanges
                              : context.l10n.createPublish,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _categoryIcons = {
  'musica': Icons.music_note_outlined,
  'teatre': Icons.theater_comedy_outlined,
  'exposicions': Icons.palette_outlined,
};

IconData _categoryIcon(String category) =>
    _categoryIcons[canonicalActivityCategoryKey(category)] ??
    Icons.local_activity_outlined;

/// Fila horitzontal de categories que es pot desplaçar. Cada una té els
/// colors de la seva insígnia; se'n poden triar fins a [maxActivityCategories].
class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<ActivityCategory> categories;

  /// `ActivityCategory.value` de les triades.
  final List<String> selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final languageCode = context.l10n.localeName;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final label = localizeActivityCategory(
            category.label,
            languageCode: languageCode,
          );
          return _CategoryPill(
            label: label,
            icon: _categoryIcon(category.label),
            colors: ActivityCategoryBadge.colorsFor(category.label, colors),
            isSelected: selected.contains(category.value),
            onTap: () => onSelected(category.value),
          );
        },
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.icon,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final ({Color background, Color foreground}) colors;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Seleccionada: fons del color fort i text clar; si no, els colors suaus
    // de la insígnia.
    final background = isSelected ? colors.foreground : colors.background;
    final foreground = isSelected
        ? Theme.of(context).colorScheme.onPrimary
        : colors.foreground;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: StadiumBorder(
          side: BorderSide(color: colors.foreground, width: isSelected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check : icon,
                  size: 20,
                  color: foreground,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Portada de l'activitat, a dalt del formulari. Sempre n'hi ha una (la
/// primera plantilla per defecte); el botó del llapis obre el panell per
/// canviar-la.
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.imageAsset, required this.onSelected});

  final String imageAsset;
  final ValueChanged<String> onSelected;

  Future<void> _change(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _CoverImageSheet(selected: imageAsset),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: context.l10n.createCoverSemantics,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _change(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: colors.surfaceContainerHighest,
                    child: const Icon(Icons.image_outlined, size: 48),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: IconButton.filled(
                    onPressed: () => _change(context),
                    tooltip: context.l10n.createChangeImage,
                    icon: const Icon(Icons.edit_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surface,
                      foregroundColor: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Panell per canviar la portada: pujar una foto pròpia (encara no
/// disponible, Taiga #94) o triar una de les plantilles.
class _CoverImageSheet extends StatelessWidget {
  const _CoverImageSheet({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.createCoverTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // Preparat per a la tasca #94: de moment no es pot pujar.
            Tooltip(
              message: context.l10n.createUploadSoonTooltip,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                // TODO(DP-019): activar amb la tasca #94.
                label: Text(context.l10n.createUploadSoon),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.createOrPickOurs,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (index, asset) in activityImageTemplates.indexed)
                  _ImageOption(
                    label: context.l10n.createImageOption(index + 1),
                    isSelected: selected == asset,
                    onTap: () => Navigator.of(context).pop(asset),
                    child: Image.asset(asset, fit: BoxFit.cover),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageOption extends StatelessWidget {
  const _ImageOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 88,
          height: 88,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (isSelected)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.check_circle, color: colors.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
