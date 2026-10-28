import 'package:flutter/material.dart';

/// Shrinks to its messages, leaving the map interactive outside the notices.
class MapFilterFeedback extends StatelessWidget {
  const MapFilterFeedback({
    super.key,
    required this.isEmpty,
    required this.missingCategories,
    required this.onClear,
    this.onShowList,
  });

  final bool isEmpty;
  final int missingCategories;
  final VoidCallback onClear;
  final VoidCallback? onShowList;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        key: const ValueKey('activity-map-filter-feedback'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEmpty && missingCategories == 0)
              MapFilterNotice(onClear: onClear),
            if (missingCategories > 0)
              MissingCategoryNotice(
                count: missingCategories,
                onShowList: onShowList,
              ),
            if (isEmpty && missingCategories > 0)
              TextButton(
                onPressed: onClear,
                child: const Text('Netejar filtres'),
              ),
          ],
        ),
      ),
    ),
  );
}

class FilteredActivitiesEmptyState extends StatelessWidget {
  const FilteredActivitiesEmptyState({
    super.key,
    required this.onClear,
    required this.missingCategories,
    this.isPartialCatalogue = false,
    this.scrollable = true,
  });
  final VoidCallback onClear;
  final int missingCategories;
  final bool isPartialCatalogue;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt_off_outlined, size: 36),
          const SizedBox(height: 12),
          Text(
            isPartialCatalogue
                ? 'Cap coincidència entre les activitats carregades'
                : 'No hi ha activitats amb aquests filtres',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Prova unes altres dates o categories.',
            textAlign: TextAlign.center,
          ),
          if (missingCategories > 0)
            MissingCategoryNotice(count: missingCategories),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onClear,
            child: const Text('Netejar filtres'),
          ),
        ],
      ),
    );
    return Center(
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }
}

class MapFilterNotice extends StatelessWidget {
  const MapFilterNotice({super.key, required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No hi ha activitats amb aquests filtres en aquesta zona.',
          ),
          TextButton(onPressed: onClear, child: const Text('Netejar filtres')),
        ],
      ),
    ),
  );
}

class MissingCategoryNotice extends StatelessWidget {
  const MissingCategoryNotice({
    super.key,
    required this.count,
    this.onShowList,
  });
  final int count;
  final VoidCallback? onShowList;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count == 1
                ? '1 activitat sense categoria informada no s’inclou en aquest filtre.'
                : '$count activitats sense categoria informada no s’inclouen en aquest filtre.',
          ),
          if (onShowList != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Consulta la llista per veure els resultats per categoria.',
            ),
            TextButton(
              onPressed: onShowList,
              child: const Text('Veure llista'),
            ),
          ],
        ],
      ),
    ),
  );
}
