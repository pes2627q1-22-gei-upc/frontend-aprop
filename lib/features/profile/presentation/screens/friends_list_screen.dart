import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../repositories/friends_repository.dart';
import '../../repositories/friendship_repository.dart';
import '../../models/user_summary.dart';
import '../view_models/friends_list_view_model.dart';
import '../widgets/user_row.dart';
import '../widgets/friend_removal_action.dart';

/// «Amics» (#54): opened from the friends counter of a profile.
class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({
    super.key,
    required this.repository,
    required this.onUserSelected,
    this.userId,
    this.ownerName,
    this.hiddenIds = const {},
    this.friendshipRepository,
    this.currentUserId,
  });

  final FriendsRepository repository;
  final ValueChanged<String> onUserSelected;

  /// Whose friends; null for the signed-in person.
  final String? userId;

  /// The person's name, for the empty message of another profile.
  final String? ownerName;
  final Set<String> hiddenIds;
  final FriendshipRepository? friendshipRepository;
  final String? currentUserId;

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  late FriendsListViewModel _viewModel;
  bool _confirmationOpen = false;

  FriendsListViewModel _createModel() => FriendsListViewModel(
    repository: widget.repository,
    userId: widget.userId,
    hiddenIds: widget.hiddenIds,
    friendshipRepository: widget.friendshipRepository,
    currentUserId: widget.currentUserId,
  )..load();

  @override
  void initState() {
    super.initState();
    _viewModel = _createModel();
  }

  @override
  void didUpdateWidget(covariant FriendsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.userId != widget.userId ||
        oldWidget.friendshipRepository != widget.friendshipRepository ||
        oldWidget.currentUserId != widget.currentUserId ||
        !setEquals(oldWidget.hiddenIds, widget.hiddenIds)) {
      _viewModel.dispose();
      _viewModel = _createModel();
      _confirmationOpen = false;
    }
  }

  Future<void> _removeFriend(UserSummary friend) async {
    if (_confirmationOpen ||
        !_viewModel.canRemoveFriends ||
        _viewModel.isRemoving(friend.id)) {
      return;
    }
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final model = _viewModel;
    _confirmationOpen = true;
    final confirmed = await confirmFriendRemoval(context, friend.displayName);
    if (!mounted || !identical(model, _viewModel)) return;
    _confirmationOpen = false;
    if (!confirmed) return;
    final removed = await model.removeFriend(friend.id);
    if (!mounted ||
        !identical(model, _viewModel) ||
        !removed ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.friendRemoveSuccess(friend.displayName)),
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: context.l10n.goBack,
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(context.l10n.friendsTitle),
    ),
    body: ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final model = _viewModel;
        final friends = model.friends;
        return RefreshIndicator(
          onRefresh: model.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (model.isLoading)
                SliverToBoxAdapter(
                  child: friends == null
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: context.l10n.friendsLoading,
                            ),
                          ),
                        )
                      : const LinearProgressIndicator(),
                ),
              if (model.errorMessage case final error?)
                SliverToBoxAdapter(
                  child: _Message(
                    icon: Icons.refresh,
                    text: error,
                    onRetry: model.load,
                  ),
                )
              else if (friends != null && friends.isEmpty)
                SliverToBoxAdapter(
                  child: _Message(
                    icon: Icons.people_outline,
                    text: switch (widget.ownerName) {
                      final name? when widget.userId != null =>
                        context.l10n.friendsEmptyOther(name),
                      _ => context.l10n.friendsEmptyOwn,
                    },
                  ),
                ),
              if (friends != null && friends.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.separated(
                    itemCount: friends.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          UserRow(
                            key: ValueKey('friend-${friend.id}'),
                            user: friend,
                            trailing: model.canRemoveFriends
                                ? FriendRemovalAction(
                                    key: ValueKey('remove-friend-${friend.id}'),
                                    name: friend.displayName,
                                    removing: model.isRemoving(friend.id),
                                    onPressed: model.isLoading
                                        ? null
                                        : () => _removeFriend(friend),
                                  )
                                : null,
                            onTap: () {
                              if (ModalRoute.of(context)?.isCurrent ?? true) {
                                widget.onUserSelected(friend.id);
                              }
                            },
                          ),
                          if (model.removalError(friend.id) case final error?)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  error,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(text, textAlign: TextAlign.center),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ],
    ),
  );
}
