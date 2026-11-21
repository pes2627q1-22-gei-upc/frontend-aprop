import 'package:flutter/material.dart';

import '../../../../core/l10n/locale_controller.dart';
import '../../../auth/models/app_user.dart';
import '../../models/profile_settings.dart';
import '../../repositories/profile_settings_repository.dart';
import '../view_models/profile_settings_view_model.dart';
import '../widgets/settings_group.dart';
import '../widgets/settings_preference_tile.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({
    super.key,
    required this.user,
    required this.repository,
    required this.onSignOut,
    required this.onBack,
    this.onOpenInterestTest,
    this.onDeleteAccount,
    this.localeController,
  });
  final AppUser user;
  final ProfileSettingsRepository repository;
  final Future<void> Function() onSignOut;
  final VoidCallback onBack;
  final VoidCallback? onOpenInterestTest;

  /// Esborra el compte (#10). Sense, «Eliminar compte» queda pendent.
  final Future<void> Function()? onDeleteAccount;

  /// Defaults to the app's [LocaleScope] controller.
  final LocaleController? localeController;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late ProfileSettingsViewModel _viewModel;

  void _createViewModel() {
    _viewModel = ProfileSettingsViewModel(
      userId: widget.user.id,
      repository: widget.repository,
      onSignOut: widget.onSignOut,
      onDeleteAccount: widget.onDeleteAccount,
      localeController: widget.localeController ?? LocaleScope.maybeOf(context),
    )..load();
  }

  @override
  void initState() {
    super.initState();
    _createViewModel();
  }

  @override
  void didUpdateWidget(covariant ProfileSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id ||
        oldWidget.repository != widget.repository) {
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.settingsTitle),
      centerTitle: true,
      leading: IconButton(
        tooltip: context.l10n.goBack,
        onPressed: widget.onBack,
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final model = _viewModel;
        final settings = model.settings;
        return RefreshIndicator(
          onRefresh: model.load,
          child: ListView(
            key: const PageStorageKey('profile-settings-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              // Keep subsequent group indices stable during loading/saving/errors.
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (model.isLoading)
                    LinearProgressIndicator(
                      semanticsLabel: context.l10n.settingsLoading,
                    ),
                  if (model.errorMessage case final error?) ...[
                    Text(error, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: model.load,
                      child: Text(context.l10n.retry),
                    ),
                  ],
                  if (model.actionError case final error?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
              ),
              if (settings != null) ...[
                // TODO(DP-033): Theme stays disabled until dark mode exists.
                SettingsGroup(
                  title: context.l10n.settingsGroupPreferences,
                  children: [
                    _ChoiceRow(
                      title: context.l10n.settingsLanguage,
                      icon: Icons.language,
                      options: [
                        ('ca', context.l10n.languageNameCa),
                        ('es', context.l10n.languageNameEs),
                        ('en', context.l10n.languageNameEn),
                      ],
                      selected:
                          Localizations.maybeLocaleOf(context)?.languageCode ??
                          'ca',
                      onChanged: model.hasLocaleController && !model.isBusy
                          ? (code) => model.changeLanguage(Locale(code))
                          : null,
                    ),
                    _ChoiceRow(
                      title: context.l10n.settingsTheme,
                      icon: Icons.light_mode_outlined,
                      options: [
                        ('light', context.l10n.themeLight),
                        ('dark', context.l10n.themeDark),
                      ],
                      selected: 'light',
                      tooltip: context.l10n.settingsDarkThemeSoon,
                    ),
                  ],
                ),
                SettingsGroup(
                  title: context.l10n.settingsGroupPrivacy,
                  children: [
                    _preference(
                      ProfilePreference.showMyPlans,
                      Icons.visibility_outlined,
                      context.l10n.settingsShowMyPlans,
                      context.l10n.settingsShowMyPlansHint,
                    ),
                    PendingSettingsTile(
                      title: context.l10n.settingsBlockedUsers,
                      icon: Icons.block,
                    ),
                  ],
                ),
                SettingsGroup(
                  title: context.l10n.settingsGroupNotifications,
                  children: [
                    _preference(
                      ProfilePreference.reminders,
                      Icons.notifications_outlined,
                      context.l10n.settingsReminders,
                      context.l10n.settingsRemindersHint,
                    ),
                    _preference(
                      ProfilePreference.friendActivity,
                      Icons.people_outline,
                      context.l10n.settingsFriendActivity,
                      context.l10n.settingsFriendActivityHint,
                    ),
                    _preference(
                      ProfilePreference.recommendations,
                      Icons.lightbulb_outline,
                      context.l10n.settingsRecommendations,
                      null,
                    ),
                    _preference(
                      ProfilePreference.friendRequests,
                      Icons.chat_bubble_outline,
                      context.l10n.settingsFriendRequests,
                      null,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    model.persistsPreferences
                        ? context.l10n.settingsPersistsAccount
                        : context.l10n.settingsPersistsSession,
                  ),
                ),
              ],
              SettingsGroup(
                title: context.l10n.settingsGroupAccount,
                children: [
                  PendingSettingsTile(
                    title: context.l10n.settingsGoogleCalendar,
                    icon: Icons.event_available_outlined,
                    subtitle: context.l10n.settingsGoogleCalendarHint,
                    status: context.l10n.settingsNotConnected,
                  ),
                  if (widget.onOpenInterestTest case final open?)
                    ListTile(
                      key: const ValueKey('profile-interest-test'),
                      leading: const SettingsIcon(icon: Icons.sync),
                      title: Text(context.l10n.settingsRetakeInterestTest),
                      minVerticalPadding: 12,
                      enabled: !model.isBusy,
                      onTap: model.isBusy ? null : open,
                    )
                  else
                    PendingSettingsTile(
                      title: context.l10n.settingsRetakeInterestTest,
                      icon: Icons.sync,
                    ),
                  ListTile(
                    key: const ValueKey('profile-sign-out'),
                    leading: const SettingsIcon(icon: Icons.logout),
                    title: Text(
                      model.isSigningOut
                          ? context.l10n.settingsSigningOut
                          : context.l10n.settingsSignOut,
                    ),
                    subtitle: Text(widget.user.email),
                    minVerticalPadding: 12,
                    enabled: !model.isBusy,
                    onTap: model.isBusy ? null : model.signOut,
                  ),
                  if (model.canDeleteAccount)
                    ListTile(
                      key: const ValueKey('profile-delete-account'),
                      leading: const SettingsIcon(
                        icon: Icons.delete_outline,
                        danger: true,
                      ),
                      title: Text(
                        model.isDeletingAccount
                            ? context.l10n.settingsDeletingAccount
                            : context.l10n.settingsDeleteAccount,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      minVerticalPadding: 12,
                      enabled: !model.isBusy,
                      onTap: model.isBusy ? null : _confirmDeleteAccount,
                    )
                  else
                    PendingSettingsTile(
                      title: context.l10n.settingsDeleteAccount,
                      icon: Icons.delete_outline,
                      danger: true,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  /// CA1: un diàleg explica què s'esborra i que no es pot desfer; el botó
  /// només s'activa en escriure «ELIMINAR».
  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;
    await _viewModel.deleteAccount();
    // L'error de dalt de tot queda fora de la pantalla des d'aquí baix.
    if (!mounted) return;
    if (_viewModel.actionError case final error?) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Widget _preference(
    ProfilePreference preference,
    IconData icon,
    String title,
    String? subtitle,
  ) {
    final model = _viewModel;
    if (!model.supports(preference)) {
      return PendingSettingsTile(
        title: title,
        icon: icon,
        subtitle: context.l10n.comingSoon,
      );
    }
    // TODO(DP-078): This controls sharing plans with friends, not public events.
    return SettingsPreferenceTile(
      switchKey: ValueKey('profile-preference-${preference.name}'),
      icon: icon,
      title: title,
      hint: subtitle,
      value: model.settings!.valueOf(preference),
      status: preference == ProfilePreference.showMyPlans
          ? model.settings!.showMyPlans
                ? context.l10n.settingsPlansShared
                : context.l10n.settingsPlansPrivate
          : null,
      saving: model.savingPreference == preference,
      error: model.failedPreference == preference
          ? model.preferenceError
          : null,
      onRetry: model.canRetryPreference ? model.retryPreference : null,
      onChanged: model.canUpdatePreference(preference)
          ? (value) => model.updatePreference(preference, value)
          : null,
    );
  }
}

/// Segmented choice. Without [onChanged] it is shown disabled.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.icon,
    required this.options,
    required this.selected,
    this.onChanged,
    this.tooltip,
  });
  final String title;
  final IconData icon;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String>? onChanged;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final control = Tooltip(
      message: tooltip ?? '',
      child: SegmentedButton<String>(
        segments: [
          for (final (value, label) in options)
            ButtonSegment(
              value: value,
              label: Text(label),
              enabled: onChanged != null,
            ),
        ],
        selected: {selected},
        onSelectionChanged: onChanged == null
            ? null
            : (values) => onChanged!(values.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.surface
                : colors.surfaceContainerHighest,
          ),
          foregroundColor: WidgetStatePropertyAll(colors.onSurface),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final label = Row(
            children: [
              SettingsIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          );
          if (constraints.maxWidth < (options.length > 2 ? 460 : 330) ||
              MediaQuery.textScalerOf(context).scale(14) > 21) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [label, const SizedBox(height: 8), control],
            );
          }
          return Row(
            children: [
              Expanded(child: label),
              const SizedBox(width: 8),
              control,
            ],
          );
        },
      ),
    );
  }
}

/// Confirmació d'«Eliminar compte» (#10): cal escriure la paraula per evitar
/// esborrar el compte d'un toc.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final word = context.l10n.settingsDeleteAccountWord;
    return AlertDialog(
      title: Text(context.l10n.settingsDeleteAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.settingsDeleteAccountBody),
            const SizedBox(height: 16),
            Text(context.l10n.settingsDeleteAccountTypeWord(word)),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('profile-delete-account-word'),
              controller: _text,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: context.l10n.settingsDeleteAccountHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('profile-delete-account-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: _text.text.trim().toUpperCase() == word.toUpperCase()
              ? () => Navigator.of(context).pop(true)
              : null,
          child: Text(context.l10n.settingsDeleteAccountConfirm),
        ),
      ],
    );
  }
}
