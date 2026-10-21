import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../repositories/discovery_repository.dart';
import '../view_models/discover_view_model.dart';
import '../view_models/enrollment_view_model.dart';
import '../widgets/activity_card.dart';
import '../widgets/discovery_message.dart';
import '../widgets/enrollment_action.dart';

/// Section content; MainShell owns its AppBar and the bottom navigation.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.userId,
    required this.repository,
    required this.enrollmentViewModel,
    required this.onSearchPressed,
    required this.onActivitySelected,
  });

  final String userId;
  final DiscoveryRepository repository;
  final EnrollmentViewModel enrollmentViewModel;
  final VoidCallback onSearchPressed;
  final ValueChanged<String> onActivitySelected;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late DiscoverViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _createViewModel();
  }

  void _createViewModel() {
    _viewModel = DiscoverViewModel(
      repository: widget.repository,
      userId: widget.userId,
    )..load();
  }

  @override
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.userId != widget.userId) {
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
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final feed = _viewModel.feed;
        return RefreshIndicator(
          onRefresh: _viewModel.load,
          child: CustomScrollView(
            key: const PageStorageKey('discover-feed'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: OutlinedButton(
                    key: const ValueKey('discover-search'),
                    onPressed: widget.onSearchPressed,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      padding: const EdgeInsets.all(16),
                      backgroundColor: theme.colorScheme.surface,
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cerca activitats',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_viewModel.isLoading && feed == null)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Carregant propostes',
                      ),
                    ),
                  ),
                ),
              if (_viewModel.isLoading && feed != null)
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
              if (_viewModel.errorMessage case final error?)
                SliverToBoxAdapter(
                  child: DiscoveryMessage(
                    icon: Icons.refresh,
                    title: error,
                    onRetry: _viewModel.load,
                  ),
                ),
              if (feed != null)
                if (feed.isEmpty)
                  const SliverToBoxAdapter(
                    child: DiscoveryMessage(
                      icon: Icons.explore_outlined,
                      title: 'Encara no hi ha propostes',
                      description: 'Pots cercar activitats o tornar-ho a provar més tard.',
                    ),
                  )
                else ...[
                  ..._section(
                    title: 'Per a tu',
                    // TODO(DP-024): Show the interests subtitle only when the
                    // repository actually supplies personalized recommendations.
                    subtitle: feed.isPersonalized
                        ? 'Segons els teus interessos'
                        : 'Una selecció per començar',
                    activities: feed.recommended,
                    keyPrefix: 'discover-recommended',
                    emptyText: 'No hi ha recomanacions disponibles.',
                  ),
                  ..._section(
                    title: 'Destacats',
                    activities: feed.featured,
                    keyPrefix: 'discover-featured',
                    emptyText: 'No hi ha activitats destacades.',
                  ),
                ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _section({
    required String title,
    required List<Activity> activities,
    required String keyPrefix,
    required String emptyText,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: activities.isEmpty
            ? SliverToBoxAdapter(child: Text(emptyText))
            : SliverList.separated(
                itemCount: activities.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return ActivityCard(
                    key: ValueKey('$keyPrefix-${activity.id}'),
                    activity: activity,
                    onTap: () => widget.onActivitySelected(activity.id),
                    participationAction: EnrollmentAction(
                      viewModel: widget.enrollmentViewModel,
                      activityId: activity.id,
                      activityTitle: activity.title,
                    ),
                  );
                },
              ),
      ),
    ];
  }
}
