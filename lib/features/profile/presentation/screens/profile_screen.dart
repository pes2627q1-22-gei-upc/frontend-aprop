import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../view_models/profile_view_model.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/profile_activity_tile.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_progress_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.viewModel,
    required this.onSettingsPressed,
    required this.onActivitySelected,
    this.onSharePressed,
  });
  final ProfileViewModel viewModel;
  final VoidCallback onSettingsPressed;
  final VoidCallback? onSharePressed;
  final ValueChanged<String> onActivitySelected;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;

  void _edit() {
    widget.viewModel.clearSaveError();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => EditProfileSheet(viewModel: widget.viewModel),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.viewModel.user.username ?? 'Perfil',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      actions: [
        const Tooltip(
          message: 'Cerca de persones disponible properament',
          child: IconButton(
            onPressed: null,
            icon: Icon(Icons.person_add_alt_1_outlined),
          ),
        ),
        IconButton(
          tooltip: 'Configuració',
          onPressed: widget.onSettingsPressed,
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        final model = widget.viewModel;
        final profile = model.profile;
        final activities = profile == null
            ? const <Activity>[]
            : _selectedTab == 0
            ? profile.completedPlans.map((plan) => plan.activity).toList()
            : profile.createdActivities;
        return RefreshIndicator(
          onRefresh: model.load,
          child: CustomScrollView(
            key: const PageStorageKey('profile-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (model.isLoading)
                SliverToBoxAdapter(
                  child: profile == null
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Carregant el perfil',
                            ),
                          ),
                        )
                      : const LinearProgressIndicator(),
                ),
              if (model.errorMessage case final error?)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(error, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: model.load,
                          child: const Text('Tornar-ho a provar'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (profile != null) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        ProfileHeader(
                          profile: profile,
                          onEdit: model.isLoading || model.isSaving
                              ? null
                              : _edit,
                          onShare: widget.onSharePressed,
                        ),
                        const SizedBox(height: 24),
                        ProfileProgressSection(progress: profile.progress),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: DefaultTabController(
                    length: 2,
                    initialIndex: _selectedTab,
                    child: TabBar(
                      onTap: (index) => setState(() => _selectedTab = index),
                      tabs: [
                        for (final tab in [
                          (Icons.event_available_outlined, 'Plans fets'),
                          (Icons.edit_note, 'Creats per mi'),
                        ])
                          Tab(
                            height:
                                MediaQuery.textScalerOf(context).scale(14) > 21
                                ? 88
                                : 56,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(tab.$1),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    tab.$2,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (activities.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            _selectedTab == 0
                                ? Icons.event_available_outlined
                                : Icons.edit_calendar_outlined,
                            size: 36,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedTab == 0
                                ? 'Encara no tens plans fets'
                                : 'Encara no has creat cap activitat',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedTab == 0
                                ? 'Aquí veuràs les activitats amb assistència confirmada.'
                                : 'Pots crear-ne una des d’Inici.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) => SliverGrid.builder(
                        itemCount: activities.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              constraints.crossAxisExtent < 330 ||
                                  MediaQuery.textScalerOf(context).scale(14) >
                                      21
                              ? 2
                              : 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: .75,
                        ),
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return ProfileActivityTile(
                            key: ValueKey('profile-activity-${activity.id}'),
                            activity: activity,
                            rating: _selectedTab == 0
                                ? profile.completedPlans[index].rating
                                : null,
                            onTap: () => widget.onActivitySelected(activity.id),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
