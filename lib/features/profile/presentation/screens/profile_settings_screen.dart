import 'package:flutter/material.dart';

import '../../../auth/models/app_user.dart';
import '../../models/profile_settings.dart';
import '../../repositories/profile_settings_repository.dart';
import '../view_models/profile_settings_view_model.dart';
import '../widgets/settings_group.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({
    super.key,
    required this.user,
    required this.repository,
    required this.onSignOut,
    required this.onBack,
  });
  final AppUser user;
  final ProfileSettingsRepository repository;
  final Future<void> Function() onSignOut;
  final VoidCallback onBack;

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
      title: const Text('Configuració'),
      centerTitle: true,
      leading: IconButton(
        tooltip: 'Tornar enrere',
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
                    const LinearProgressIndicator(
                      semanticsLabel: 'Carregant la configuració',
                    ),
                  if (model.errorMessage case final error?) ...[
                    Text(error, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: model.load,
                      child: const Text('Tornar-ho a provar'),
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
                  if (model.savingPreference != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: const Text('Desant el canvi…'),
                      ),
                    ),
                ],
              ),
              if (settings != null) ...[
                // TODO(DP-033): Activate language/theme only when they apply to
                // the whole app. These controls must not pretend to change them.
                const SettingsGroup(
                  title: 'PREFERÈNCIES',
                  children: [
                    _PendingChoiceRow(
                      title: 'Idioma',
                      icon: Icons.language,
                      options: ['Català', 'Castellà'],
                      tooltip: 'Canvi d’idioma disponible properament',
                    ),
                    _PendingChoiceRow(
                      title: 'Tema',
                      icon: Icons.light_mode_outlined,
                      options: ['Clar', 'Fosc'],
                      tooltip: 'Tema fosc disponible properament',
                    ),
                  ],
                ),
                SettingsGroup(
                  title: 'PRIVACITAT',
                  children: [
                    _preference(
                      ProfilePreference.showMyPlans,
                      Icons.visibility_outlined,
                      'Mostrar els meus plans',
                      'Els amics veuen a què t’apuntes',
                    ),
                    const PendingSettingsTile(
                      title: 'Usuaris bloquejats',
                      icon: Icons.block,
                    ),
                  ],
                ),
                SettingsGroup(
                  title: 'NOTIFICACIONS',
                  children: [
                    _preference(
                      ProfilePreference.reminders,
                      Icons.notifications_outlined,
                      'Recordatoris',
                      'Avisos dels plans de la teva agenda',
                    ),
                    _preference(
                      ProfilePreference.friendActivity,
                      Icons.people_outline,
                      'Activitat dels amics',
                      'Quan un amic s’apunta a un pla',
                    ),
                    _preference(
                      ProfilePreference.recommendations,
                      Icons.lightbulb_outline,
                      'Recomanacions',
                      null,
                    ),
                    _preference(
                      ProfilePreference.friendRequests,
                      Icons.chat_bubble_outline,
                      'Sol·licituds d’amistat',
                      null,
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    model.persistsPreferences
                        ? 'Els canvis disponibles es desen al teu compte.'
                        : 'Les preferències es conserven durant aquesta sessió de l’app.',
                  ),
                ),
              ],
              SettingsGroup(
                title: 'COMPTE',
                children: [
                  const PendingSettingsTile(
                    title: 'Google Calendar',
                    icon: Icons.event_available_outlined,
                    subtitle: 'Exportació disponible properament',
                    status: 'No connectat',
                  ),
                  const PendingSettingsTile(
                    title: 'Tornar a fer el test d’interessos',
                    icon: Icons.sync,
                  ),
                  ListTile(
                    key: const ValueKey('profile-sign-out'),
                    leading: const SettingsIcon(icon: Icons.logout),
                    title: Text(
                      model.isSigningOut ? 'Tancant sessió…' : 'Tancar sessió',
                    ),
                    subtitle: Text(widget.user.email),
                    minVerticalPadding: 12,
                    enabled: !model.isBusy,
                    onTap: model.isBusy ? null : model.signOut,
                  ),
                  const PendingSettingsTile(
                    title: 'Eliminar compte',
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
        subtitle: 'Disponible properament',
      );
    }
    return SwitchListTile.adaptive(
      key: ValueKey('profile-preference-${preference.name}'),
      secondary: SettingsIcon(icon: icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      value: model.settings!.valueOf(preference),
      onChanged: model.isBusy || model.isLoading
          ? null
          : (value) => model.updatePreference(preference, value),
    );
  }
}

class _PendingChoiceRow extends StatelessWidget {
  const _PendingChoiceRow({
    required this.title,
    required this.icon,
    required this.options,
    required this.tooltip,
  });
  final String title;
  final IconData icon;
  final List<String> options;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final control = Tooltip(
      message: tooltip,
      child: SegmentedButton<String>(
        segments: [
          for (final option in options)
            ButtonSegment(value: option, label: Text(option), enabled: false),
        ],
        selected: {options.first},
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
          if (constraints.maxWidth < 330 ||
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
