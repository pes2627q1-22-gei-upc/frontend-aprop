import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../models/activity_options.dart';
import '../../repositories/activity_repository.dart';
import '../formatters/activity_date_formatter.dart';
import '../widgets/activity_badges.dart';
import '../view_models/create_activity_view_model.dart';
import '../widgets/start_date_time_sheet.dart';

/// Formulari per publicar una activitat no oficial (Taiga #31).
// TODO(DP-021): disseny sense mockup aprovat, pendent de validar.

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({
    super.key,
    required this.repository,
    required this.creator,
    required this.onCreated,
    this.now = DateTime.now,
  });

  final ActivityRepository repository;
  final ActivityCreator creator;

  /// Rep l'activitat publicada. Qui obre la pantalla decideix què es mostra
  /// després (la fitxa de l'activitat nova).
  final ValueChanged<Activity> onCreated;

  /// Rellotge per validar la data d'inici; les proves el fixen.
  final DateTime Function() now;

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _directionsController = TextEditingController();
  final _priceController = TextEditingController();
  late final CreateActivityViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CreateActivityViewModel(
      repository: widget.repository,
      creator: widget.creator,
      now: widget.now,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _municipalityController.dispose();
    _directionsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickStartsAt() async {
    FocusScope.of(context).unfocus();
    final tomorrow = _viewModel.today.add(const Duration(days: 1));

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

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();

    final activity = await _viewModel.publish(
      title: _titleController.text,
      description: _descriptionController.text,
      municipality: _municipalityController.text,
      directions: _directionsController.text,
      price: _priceController.text,
    );
    if (activity != null && mounted) widget.onCreated(activity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crea una activitat')),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) {
            final errorMessage = _viewModel.errorMessage;
            final startsAt = _viewModel.startsAt;

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
                    labelText: 'Títol',
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
                    labelText: 'Descripció',
                    alignLabelWithHint: true,
                    errorText: _viewModel.fieldError(
                      CreateActivityField.description,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Categoria', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _CategorySelector(
                  selected: _viewModel.category,
                  onSelected: _viewModel.setCategory,
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
                      labelText: 'Data i hora d’inici',
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                      errorText: _viewModel.fieldError(
                        CreateActivityField.startsAt,
                      ),
                    ),
                    child: Text(
                      startsAt == null
                          ? 'Tria la data i l’hora'
                          : formatActivitySchedule(startsAt, includeDate: true),
                      style: startsAt == null
                          ? TextStyle(color: colors.onSurfaceVariant)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // TODO(DP-020): falta el punt exacte al mapa (coordenades).
                TextField(
                  controller: _municipalityController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _viewModel.onFieldChanged(
                    CreateActivityField.municipality,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Municipi',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    errorText: _viewModel.fieldError(
                      CreateActivityField.municipality,
                    ),
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
                  decoration: const InputDecoration(
                    labelText: 'Indicacions (opcional)',
                    prefixIcon: Icon(Icons.signpost_outlined),
                    hintText: 'Per exemple: entrada pel pati, 2n pis',
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
                    labelText: 'Preu (opcional)',
                    prefixIcon: const Icon(Icons.sell_outlined),
                    suffixText: '€',
                    helperText: 'Deixa-ho buit si és gratuïta.',
                    errorText: _viewModel.fieldError(CreateActivityField.price),
                  ),
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
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            semanticsLabel: 'Publicant',
                          ),
                        )
                      : const Text('Publica'),
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
  'Música': Icons.music_note_outlined,
  'Teatre': Icons.theater_comedy_outlined,
  'Exposicions': Icons.palette_outlined,
};

IconData _categoryIcon(String category) =>
    _categoryIcons[category] ?? Icons.local_activity_outlined;

/// Fila horitzontal de categories que es pot desplaçar. Cada una té els
/// colors de la seva insígnia; només se'n pot triar una.
class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: activityCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = activityCategories[index];
          return _CategoryPill(
            label: category,
            icon: _categoryIcon(category),
            colors: ActivityCategoryBadge.colorsFor(category, colors),
            isSelected: selected == category,
            onTap: () => onSelected(category),
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
      label: 'Imatge de portada. Canvia la imatge',
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
                    tooltip: 'Canvia la imatge',
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
              'Imatge de portada',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            // Preparat per a la tasca #94: de moment no es pot pujar.
            Tooltip(
              message: 'Pujar fotos estarà disponible properament',
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                // TODO(DP-019): activar amb la tasca #94.
                label: const Text('Puja una foto (properament)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'O tria una de les nostres',
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
                    label: 'Imatge ${index + 1}',
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
