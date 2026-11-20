import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../../profile/repositories/user_search_repository.dart';
import '../view_models/user_search_view_model.dart';
import 'discovery_message.dart';
import '../../../profile/presentation/widgets/user_row.dart';

class UserSearchResults extends StatelessWidget {
  const UserSearchResults({
    super.key,
    required this.viewModel,
    required this.onUserSelected,
  });

  final UserSearchViewModel viewModel;
  final ValueChanged<String> onUserSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = viewModel.query.trim();
    if (query.isEmpty) {
      return SingleChildScrollView(
        child: DiscoveryMessage(
          icon: Icons.person_search_outlined,
          title: l10n.userSearchPromptTitle,
          description: l10n.userSearchPromptBody,
        ),
      );
    }
    if (!viewModel.hasSearched) {
      if (viewModel.errorMessage case final error?) {
        return SingleChildScrollView(
          child: DiscoveryMessage(
            icon: Icons.person_search_outlined,
            title: error,
            onRetry: query.runes.length > userSearchQueryLimit
                ? null
                : viewModel.searchNow,
          ),
        );
      }
      return Center(
        child: CircularProgressIndicator(
          semanticsLabel: l10n.userSearchSearching,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: viewModel.searchNow,
      child: CustomScrollView(
        key: PageStorageKey('user-search-results-$query'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (viewModel.isSearching)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
          if (viewModel.errorMessage case final error?)
            SliverToBoxAdapter(
              child: DiscoveryMessage(
                icon: Icons.refresh,
                title: error,
                onRetry: viewModel.searchNow,
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                liveRegion: true,
                child: Text(l10n.userSearchCount(viewModel.totalCount)),
              ),
            ),
          ),
          if (viewModel.results.isEmpty)
            SliverToBoxAdapter(
              child: DiscoveryMessage(
                icon: Icons.person_search_outlined,
                title: l10n.userSearchNoResultsTitle,
                description: l10n.userSearchNoResultsBody,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: viewModel.results.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = viewModel.results[index];
                  return UserRow(
                    key: ValueKey('user-search-${user.id}'),
                    user: user,
                    onTap: () => onUserSelected(user.id),
                  );
                },
              ),
            ),
          if (viewModel.hasMore)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Text(l10n.userSearchLoaded(viewModel.results.length)),
                    const SizedBox(height: 8),
                    if (viewModel.pageError case final error?) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(error, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (viewModel.isLoadingMore)
                      CircularProgressIndicator(
                        semanticsLabel: l10n.userSearchSearching,
                      )
                    else
                      OutlinedButton(
                        key: const ValueKey('users-load-more'),
                        onPressed: viewModel.loadMore,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        child: Text(
                          viewModel.pageError == null
                              ? l10n.userSearchLoadMore
                              : l10n.retry,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
