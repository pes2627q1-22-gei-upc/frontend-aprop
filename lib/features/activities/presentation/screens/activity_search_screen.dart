import 'package:flutter/material.dart';

import '../../repositories/discovery_repository.dart';
import '../view_models/activity_search_view_model.dart';
import '../view_models/enrollment_view_model.dart';
import '../widgets/activity_card.dart';
import '../widgets/discovery_message.dart';
import '../widgets/enrollment_action.dart';

class ActivitySearchScreen extends StatefulWidget {
  const ActivitySearchScreen({
    super.key,
    required this.repository,
    required this.enrollmentViewModel,
    required this.onActivitySelected,
    required this.onBack,
  });

  final DiscoveryRepository repository;
  final EnrollmentViewModel enrollmentViewModel;
  final ValueChanged<String> onActivitySelected;
  final VoidCallback onBack;

  @override
  State<ActivitySearchScreen> createState() => _ActivitySearchScreenState();
}

class _ActivitySearchScreenState extends State<ActivitySearchScreen> {
  late ActivitySearchViewModel _viewModel;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = ActivitySearchViewModel(repository: widget.repository);
  }

  @override
  void didUpdateWidget(covariant ActivitySearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _viewModel.dispose();
      _controller.clear();
      _viewModel = ActivitySearchViewModel(repository: widget.repository);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca'),
        leading: IconButton(
          tooltip: 'Tornar enrere',
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                key: const ValueKey('activity-search-input'),
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _viewModel.updateQuery,
                onSubmitted: (_) {
                  _focusNode.unfocus();
                  _viewModel.searchNow();
                },
                decoration: InputDecoration(
                  hintText: 'Cerca activitats…',
                  labelText: 'Cerca activitats',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Esborrar la cerca',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: () {
                            _controller.clear();
                            _viewModel.updateQuery('');
                            _focusNode.requestFocus();
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                // TODO(DP-024): Enable people search only with its real
                // contract and a usable destination profile.
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Activitats')),
                    ButtonSegment(
                      value: false,
                      enabled: false,
                      label: Tooltip(
                        message: 'Cerca de persones disponible properament',
                        child: Text('Persones'),
                      ),
                    ),
                  ],
                  selected: const {true},
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(Size(48, 48)),
                  ),
                  onSelectionChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final query = _viewModel.query.trim();
    if (query.isEmpty) {
      return const SingleChildScrollView(
        child: DiscoveryMessage(
          icon: Icons.search,
          title: 'Quina activitat busques?',
          description: 'Cerca pel títol, el municipi o la categoria.',
        ),
      );
    }
    if (_viewModel.isSearching ||
        (!_viewModel.hasSearched && _viewModel.errorMessage == null)) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Cercant activitats'),
      );
    }
    if (_viewModel.errorMessage case final error?) {
      return SingleChildScrollView(
        child: DiscoveryMessage(
          icon: Icons.refresh,
          title: error,
          onRetry: _viewModel.searchNow,
        ),
      );
    }
    final results = _viewModel.results;
    return RefreshIndicator(
      onRefresh: _viewModel.searchNow,
      child: CustomScrollView(
        key: PageStorageKey('activity-search-results-$query'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  results.length == 1
                      ? '1 activitat trobada'
                      : '${results.length} activitats trobades',
                ),
              ),
            ),
          ),
          if (results.isEmpty)
            const SliverToBoxAdapter(
              child: DiscoveryMessage(
                icon: Icons.search_off,
                title: 'No hem trobat activitats',
                description: 'Prova amb altres paraules.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: results.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final activity = results[index];
                  return ActivityCard(
                    key: ValueKey('activity-search-${activity.id}'),
                    activity: activity,
                    onTap: () {
                      _focusNode.unfocus();
                      widget.onActivitySelected(activity.id);
                    },
                    participationAction: EnrollmentAction(
                      viewModel: widget.enrollmentViewModel,
                      activityId: activity.id,
                      activityTitle: activity.title,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
