import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../models/activity_options.dart';
import '../../repositories/activity_repository.dart';
import '../formatters/activity_date_formatter.dart';
import '../widgets/activity_badges.dart';
import '../view_models/create_activity_view_model.dart';

/// Formulari per publicar una activitat no oficial (Taiga #31).
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
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickStartsAt() async {
    FocusScope.of(context).unfocus();
    final today = _viewModel.today;
    final current = _viewModel.startsAt;

    final date = await showDatePicker(
      context: context,
      initialDate: current ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
      helpText: 'Data d’inici',
      cancelText: 'Cancel·la',
      confirmText: 'D’acord',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 19, minute: 0)
          : TimeOfDay.fromDateTime(current),
      helpText: 'Hora d’inici',
      cancelText: 'Cancel·la',
      confirmText: 'D’acord',
      // En català es fa servir el format de 24 hores, sense AM/PM.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;

    _viewModel.setStartsAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _publish() async {
    FocusScope.of(context).unfocus();

    final activity = await _viewModel.publish(
      title: _titleController.text,
      description: _descriptionController.text,
      municipality: _municipalityController.text,
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
            final imageError = _viewModel.fieldError(CreateActivityField.image);

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
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
                _CategoryField(
                  selected: _viewModel.category,
                  errorText: _viewModel.fieldError(
                    CreateActivityField.category,
                  ),
                  onSelected: _viewModel.setCategory,
                ),
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
                Text('Imatge', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _ImageTemplatePicker(
                  selected: _viewModel.imageAsset,
                  onSelected: _viewModel.setImageAsset,
                ),
                if (imageError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    imageError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ],
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

/// Camp amb l'aspecte dels altres del formulari. Mostra la categoria triada
/// amb els colors de la seva insígnia i, en prémer-lo, obre la llista en un
/// panell inferior.
class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.selected,
    required this.errorText,
    required this.onSelected,
  });

  final String? selected;
  final String? errorText;
  final ValueChanged<String> onSelected;

  Future<void> _open(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final category = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => _CategorySheet(selected: selected),
    );
    if (category != null) onSelected(category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = this.selected;

    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: 'Categoria',
          prefixIcon: Icon(
            selected == null
                ? Icons.category_outlined
                : _categoryIcon(selected),
          ),
          suffixIcon: const Icon(Icons.expand_more),
          errorText: errorText,
        ),
        child: selected == null
            ? Text(
                'Tria una categoria',
                style: TextStyle(color: colors.onSurfaceVariant),
              )
            : Align(
                alignment: Alignment.centerLeft,
                child: ActivityCategoryBadge(category: selected),
              ),
      ),
    );
  }
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Tria una categoria',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final category in activityCategories)
            _CategoryOption(
              category: category,
              colors: ActivityCategoryBadge.colorsFor(category, colors),
              isSelected: category == selected,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.colors,
    required this.isSelected,
  });

  final String category;
  final ({Color background, Color foreground}) colors;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isSelected ? colors.background : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          selected: isSelected,
          onTap: () => Navigator.of(context).pop(category),
          leading: CircleAvatar(
            backgroundColor: colors.background,
            foregroundColor: colors.foreground,
            child: Icon(_categoryIcon(category)),
          ),
          title: Text(
            category,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w700 : null,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: colors.foreground)
              : null,
        ),
      ),
    );
  }
}

/// Una de les imatges de plantilla. Mentre no es puguin pujar fotos pròpies
/// (Taiga #94), l'activitat n'ha de tenir una.
class _ImageTemplatePicker extends StatelessWidget {
  const _ImageTemplatePicker({
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (index, asset) in activityImageTemplates.indexed)
          _ImageOption(
            label: 'Imatge ${index + 1}',
            isSelected: selected == asset,
            onTap: () => onSelected(asset),
            child: Image.asset(asset, fit: BoxFit.cover),
          ),
      ],
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
