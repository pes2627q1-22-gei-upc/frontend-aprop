import 'package:flutter/material.dart';

class ActivityListPagination extends StatelessWidget {
  const ActivityListPagination({
    super.key,
    required this.loadedCount,
    required this.isLoading,
    required this.errorMessage,
    required this.onLoadMore,
  });

  final int loadedCount;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      children: [
        Text(
          loadedCount == 1
              ? '1 activitat carregada'
              : '$loadedCount activitats carregades',
        ),
        const SizedBox(height: 8),
        if (errorMessage case final error?) ...[
          Semantics(
            liveRegion: true,
            child: Text(error, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
        ],
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                semanticsLabel: 'Carregant més activitats',
              ),
            ),
          )
        else
          OutlinedButton(
            key: const ValueKey('activities-load-more'),
            onPressed: onLoadMore,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(
              errorMessage == null
                  ? 'Carregar més activitats'
                  : 'Tornar-ho a provar',
            ),
          ),
      ],
    ),
  );
}
