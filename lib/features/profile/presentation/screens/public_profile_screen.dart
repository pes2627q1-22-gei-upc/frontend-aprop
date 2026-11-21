import 'package:flutter/material.dart';

import '../../../activities/models/activity.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../repositories/public_profile_repository.dart';
import '../../repositories/friendship_repository.dart';
import '../view_models/public_profile_view_model.dart';
import '../widgets/profile_activity_tile.dart';
import '../widgets/profile_header.dart';
import '../widgets/friend_removal_action.dart';

/// Another person's profile (#277). Opened from an activity's creator or a
/// notice; MainShell pushes it on the current section's navigator.
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.repository,
    required this.onActivitySelected,
    this.onSharePressed,
    this.friendshipRepository,
    this.currentUserId,
    this.onFriendsPressed,
  });

  final String userId;
  final PublicProfileRepository repository;
  final FriendshipRepository? friendshipRepository;
  final String? currentUserId;
  final ValueChanged<String> onActivitySelected;

  /// Receives the person's username.
  final ValueChanged<String>? onSharePressed;

  /// Opens the person's friends list (#54) with their ID and name.
  final void Function(String userId, String name)? onFriendsPressed;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late PublicProfileViewModel _viewModel;
  int? _chosenTab;
  bool _confirmationOpen = false;

  PublicProfileViewModel _createModel() => PublicProfileViewModel(
    userId: widget.userId,
    repository: widget.repository,
    friendshipRepository: widget.friendshipRepository,
    currentUserId: widget.currentUserId,
  )..load();

  @override
  void initState() {
    super.initState();
    _viewModel = _createModel();
  }

  @override
  void didUpdateWidget(covariant PublicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.repository != widget.repository ||
        oldWidget.friendshipRepository != widget.friendshipRepository ||
        oldWidget.currentUserId != widget.currentUserId) {
      _viewModel.dispose();
      _viewModel = _createModel();
      _chosenTab = null;
      _confirmationOpen = false;
    }
  }

  Future<void> _removeFriend() async {
    final model = _viewModel;
    final name = model.profile?.profile.displayName;
    if (_confirmationOpen ||
        !model.canRemoveFriend ||
        name == null ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    _confirmationOpen = true;
    final confirmed = await confirmFriendRemoval(context, name);
    if (!mounted || !identical(model, _viewModel)) return;
    _confirmationOpen = false;
    if (!confirmed) return;
    final removed = await model.removeFriend();
    if (!mounted ||
        !identical(model, _viewModel) ||
        !removed ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.friendRemoveSuccess(name))),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// Plans first when they can be seen, as on the own profile.
  int get _selectedTab =>
      _chosenTab ?? ((_viewModel.profile?.plansVisible ?? false) ? 0 : 1);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, child) {
      final model = _viewModel;
      final person = model.profile;
      final username = person?.profile.username;
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: context.l10n.goBack,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            username ?? context.l10n.profileTitleFallback,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          // TODO(DP-076): friendship management lives in the other person's
          // profile; the own profile opens its editable friends list.
          actions: [
            if (model.isRemovingFriend)
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: context.l10n.friendRemoving,
                  ),
                ),
              )
            else if (model.canRemoveFriend)
              PopupMenuButton<String>(
                key: const ValueKey('public-profile-friend-options'),
                tooltip: context.l10n.friendOptions,
                onSelected: (_) => _removeFriend(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      context.l10n.friendRemove,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: model.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (model.isLoading)
                SliverToBoxAdapter(
                  child: person == null
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: context.l10n.profileLoading,
                            ),
                          ),
                        )
                      : const LinearProgressIndicator(),
                ),
              if (model.notFound)
                SliverToBoxAdapter(
                  child: _Message(
                    icon: Icons.person_off_outlined,
                    text: context.l10n.publicProfileNotFound,
                  ),
                ),
              if (model.errorMessage case final error?)
                SliverToBoxAdapter(
                  child: _Message(
                    icon: Icons.refresh,
                    text: error,
                    onRetry: model.load,
                  ),
                ),
              if (person != null) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: ProfileHeader(
                      profile: person.profile,
                      showEdit: false,
                      onEdit: null,
                      onFriendsPressed: switch (widget.onFriendsPressed) {
                        final open? => () => open(
                          widget.userId,
                          person.profile.displayName,
                        ),
                        null => null,
                      },
                      primaryAction: switch (model.friendship) {
                        null || FriendshipAction.unavailable => null,
                        final action => _FriendButton(
                          action: action,
                          enabled: !model.isLoading,
                          onPressed: model.performFriendAction,
                        ),
                      },
                      // TODO(DP-067): received actions share a row; sharing moves below.
                      secondaryAction: switch (model.friendship) {
                        FriendshipAction.incoming ||
                        FriendshipAction.accepting ||
                        FriendshipAction.rejecting => _RejectFriendButton(
                          isRejecting:
                              model.friendship == FriendshipAction.rejecting,
                          enabled:
                              model.friendship == FriendshipAction.incoming &&
                              !model.isLoading,
                          onPressed: model.rejectFriendRequest,
                        ),
                        _ => null,
                      },
                      onShare: switch ((username, widget.onSharePressed)) {
                        (final name?, final share?) when name.isNotEmpty =>
                          () => share(name),
                        _ => null,
                      },
                    ),
                  ),
                ),
                if (model.friendRequestFeedback case final message?)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(liveRegion: true, child: Text(message)),
                    ),
                  ),
                if (model.friendRequestError ??
                        (model.friendship == FriendshipAction.unavailable
                            ? context.l10n.friendRequestBlocked
                            : null)
                    case final message?)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          message,
                          style: model.friendRequestError == null
                              ? null
                              : TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: DefaultTabController(
                    // A new key applies the initial tab once the profile says
                    // whether its plans are visible.
                    key: ValueKey(person.plansVisible),
                    length: 2,
                    initialIndex: _selectedTab,
                    child: TabBar(
                      onTap: (index) => setState(() => _chosenTab = index),
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.event_available_outlined),
                          text: context.l10n.profileTabCompletedPlans,
                        ),
                        Tab(
                          icon: const Icon(Icons.edit_note),
                          text: context.l10n.publicProfileTabCreated,
                        ),
                      ],
                    ),
                  ),
                ),
                ..._tabContent(context),
              ],
            ],
          ),
        ),
      );
    },
  );

  List<Widget> _tabContent(BuildContext context) {
    final model = _viewModel;
    final person = model.profile!;
    final name = person.profile.displayName;
    if (_selectedTab == 0 && !person.plansVisible) {
      // TODO(DP-063): the texts guess the reason from `is-friend`.
      return [
        SliverToBoxAdapter(
          child: _Message(
            icon: Icons.lock_outline,
            text: person.isFriend == true
                ? context.l10n.publicProfilePlansHidden(name)
                : context.l10n.publicProfilePlansFriendsOnly(name),
          ),
        ),
      ];
    }
    final (items, isLoading, error, retry, emptyText) = _selectedTab == 0
        ? (
            model.pastPlans,
            model.isLoadingPlans,
            model.plansError,
            model.loadPastPlans,
            context.l10n.publicProfileNoPlans(name),
          )
        : (
            model.createdActivities,
            model.isLoadingCreated,
            model.createdError,
            model.loadCreatedActivities,
            context.l10n.publicProfileNoCreated(name),
          );
    return [
      if (isLoading)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        ),
      if (error != null)
        SliverToBoxAdapter(
          child: _Message(icon: Icons.refresh, text: error, onRetry: retry),
        )
      else if (items != null && items.isEmpty)
        SliverToBoxAdapter(
          child: _Message(icon: Icons.event_busy_outlined, text: emptyText),
        )
      else if (items != null)
        _ActivityGrid(
          activities: items,
          onActivitySelected: widget.onActivitySelected,
        ),
    ];
  }
}

/// «Afegeix com a amic» and the states that follow it (#160).
class _FriendButton extends StatelessWidget {
  const _FriendButton({
    required this.action,
    required this.onPressed,
    this.enabled = true,
  });

  final FriendshipAction action;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (action) {
      FriendshipAction.add => (
        Icons.person_add_alt_1_outlined,
        context.l10n.friendAdd,
      ),
      FriendshipAction.sending => (null, context.l10n.friendSending),
      FriendshipAction.checking => (null, context.l10n.profileLoading),
      FriendshipAction.accepting => (null, context.l10n.friendAccepting),
      FriendshipAction.rejecting || FriendshipAction.incoming => (
        Icons.person_add_alt_1_outlined,
        context.l10n.notifAccept,
      ),
      FriendshipAction.retry => (Icons.refresh, context.l10n.retry),
      FriendshipAction.requestSent => (
        Icons.schedule_send_outlined,
        context.l10n.friendRequestSent,
      ),
      FriendshipAction.friends || FriendshipAction.unavailable => (
        Icons.people_alt_outlined,
        context.l10n.friendAlready,
      ),
    };
    return FilledButton.icon(
      key: const ValueKey('public-profile-friend'),
      onPressed:
          {
                FriendshipAction.add,
                FriendshipAction.incoming,
                FriendshipAction.retry,
              }.contains(action) &&
              enabled
          ? onPressed
          : null,
      style: FilledButton.styleFrom(
        // Friendship is a confirmed status, so keep it legible even though
        // the button no longer offers an action.
        disabledBackgroundColor: action == FriendshipAction.friends
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        disabledForegroundColor: action == FriendshipAction.friends
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: icon == null
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label, textAlign: TextAlign.center),
    );
  }
}

/// Secondary action on the same received request as the Acceptar button.
class _RejectFriendButton extends StatelessWidget {
  const _RejectFriendButton({
    required this.isRejecting,
    required this.enabled,
    required this.onPressed,
  });
  final bool isRejecting;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: const ValueKey('public-profile-reject-friend'),
    onPressed: enabled ? onPressed : null,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    icon: isRejecting
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.person_remove_outlined),
    label: Text(
      isRejecting ? context.l10n.friendRejecting : context.l10n.notifDecline,
      textAlign: TextAlign.center,
    ),
  );
}

class _ActivityGrid extends StatelessWidget {
  const _ActivityGrid({
    required this.activities,
    required this.onActivitySelected,
  });

  final List<Activity> activities;
  final ValueChanged<String> onActivitySelected;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid.builder(
        itemCount: activities.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              constraints.crossAxisExtent < 330 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21
              ? 2
              : 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: .75,
        ),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ProfileActivityTile(
            key: ValueKey('public-profile-activity-${activity.id}'),
            activity: activity,
            onTap: () => onActivitySelected(activity.id),
          );
        },
      ),
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
