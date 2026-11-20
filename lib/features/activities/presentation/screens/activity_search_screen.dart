import 'package:flutter/material.dart';

import '../../../profile/repositories/user_search_repository.dart';
import '../../repositories/discovery_repository.dart';
import '../view_models/activity_search_view_model.dart';
import '../view_models/enrollment_view_model.dart';
import '../view_models/user_search_view_model.dart';
import '../widgets/activity_card.dart';
import '../widgets/activity_list_pagination.dart';
import '../widgets/discovery_message.dart';
import '../widgets/enrollment_action.dart';
import '../widgets/user_search_results.dart';
import '../../../../core/l10n/locale_controller.dart';

class ActivitySearchScreen extends StatefulWidget {
  const ActivitySearchScreen({
    super.key,
    required this.repository,
    required this.enrollmentViewModel,
    required this.onActivitySelected,
    required this.onBack,
    this.userSearchRepository,
    this.onUserSelected,
  });

  final DiscoveryRepository repository;
  final EnrollmentViewModel enrollmentViewModel;
  final ValueChanged<String> onActivitySelected;
  final VoidCallback onBack;
  final UserSearchRepository? userSearchRepository;
  final ValueChanged<String>? onUserSelected;

  @override
  State<ActivitySearchScreen> createState() => _ActivitySearchScreenState();
}

class _ActivitySearchScreenState extends State<ActivitySearchScreen> {
  late ActivitySearchViewModel _viewModel;
  UserSearchViewModel? _userViewModel;
  late Listenable _searchState;
  bool _searchPeople = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _createViewModels();
  }

  bool get _canSearchPeople =>
      _userViewModel != null && widget.onUserSelected != null;

  void _createViewModels() {
    _viewModel = ActivitySearchViewModel(repository: widget.repository);
    final users = widget.userSearchRepository;
    _userViewModel = users == null
        ? null
        : UserSearchViewModel(repository: users);
    _searchState = Listenable.merge([_viewModel, _userViewModel]);
  }

  void _updateQuery(String value) {
    if (_searchPeople) {
      _userViewModel!.updateQuery(value);
    } else {
      _viewModel.updateQuery(value);
    }
  }

  void _submitQuery() {
    _focusNode.unfocus();
    if (_searchPeople) {
      _userViewModel!.searchNow();
    } else {
      _viewModel.searchNow();
    }
  }

  @override
  void didUpdateWidget(covariant ActivitySearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.userSearchRepository != widget.userSearchRepository) {
      _viewModel.dispose();
      _userViewModel?.dispose();
      _controller.clear();
      _searchPeople = false;
      _createViewModels();
    }
    if (!_canSearchPeople) _searchPeople = false;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _userViewModel?.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.actSearchTitle),
        leading: IconButton(
          tooltip: context.l10n.goBack,
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListenableBuilder(
        listenable: _searchState,
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
                onChanged: _updateQuery,
                onSubmitted: (_) => _submitQuery(),
                decoration: InputDecoration(
                  hintText: _searchPeople
                      ? context.l10n.userSearchHint
                      : context.l10n.actSearchHint,
                  labelText: _searchPeople
                      ? context.l10n.userSearchLabel
                      : context.l10n.actSearchLabel,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.l10n.actClearSearch,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: () {
                            _controller.clear();
                            _viewModel.updateQuery('');
                            _userViewModel?.updateQuery('');
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
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(context.l10n.actSegActivities),
                    ),
                    ButtonSegment(
                      value: false,
                      enabled: _canSearchPeople,
                      label: Tooltip(
                        message: _canSearchPeople
                            ? ''
                            : context.l10n.profilePeopleSearchSoon,
                        child: Text(context.l10n.actSegPeople),
                      ),
                    ),
                  ],
                  selected: {!_searchPeople},
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(Size(48, 48)),
                  ),
                  onSelectionChanged: (values) {
                    setState(() => _searchPeople = !values.single);
                    _updateQuery(_controller.text);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _searchPeople
                  ? UserSearchResults(
                      viewModel: _userViewModel!,
                      onUserSelected: (id) {
                        _focusNode.unfocus();
                        widget.onUserSelected!(id);
                      },
                    )
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final query = _viewModel.query.trim();
    if (query.isEmpty) {
      return SingleChildScrollView(
        child: DiscoveryMessage(
          icon: Icons.search,
          title: context.l10n.actSearchPromptTitle,
          description: context.l10n.actSearchPromptBody,
        ),
      );
    }
    if (!_viewModel.hasSearched && _viewModel.errorMessage == null) {
      return Center(
        child: CircularProgressIndicator(
          semanticsLabel: context.l10n.actSearching,
        ),
      );
    }
    if (_viewModel.errorMessage case final error?
        when !_viewModel.hasSearched) {
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
          if (_viewModel.isSearching)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
          if (_viewModel.errorMessage case final error?)
            SliverToBoxAdapter(
              child: DiscoveryMessage(
                icon: Icons.refresh,
                title: error,
                onRetry: _viewModel.searchNow,
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                liveRegion: true,
                child: Text(context.l10n.actFoundCount(_viewModel.totalCount)),
              ),
            ),
          ),
          if (results.isEmpty)
            SliverToBoxAdapter(
              child: DiscoveryMessage(
                icon: Icons.search_off,
                title: context.l10n.actNoResultsTitle,
                description: context.l10n.actNoResultsBody,
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
          if (_viewModel.hasMore)
            SliverToBoxAdapter(
              child: ActivityListPagination(
                loadedCount: results.length,
                isLoading: _viewModel.isLoadingMore,
                errorMessage: _viewModel.pageError,
                onLoadMore: _viewModel.loadMore,
              ),
            ),
        ],
      ),
    );
  }
}
