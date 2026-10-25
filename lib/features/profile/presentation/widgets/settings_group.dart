import 'package:flutter/material.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: theme.colorScheme.outlineVariant),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsIcon extends StatelessWidget {
  const SettingsIcon({super.key, required this.icon, this.danger = false});
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = danger ? colors.error : colors.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class PendingSettingsTile extends StatelessWidget {
  const PendingSettingsTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle = 'Disponible properament',
    this.status,
    this.danger = false,
  });
  final String title;
  final IconData icon;
  final String subtitle;
  final String? status;
  final bool danger;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: '$title: disponible properament',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stackStatus =
            constraints.maxWidth < 350 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        return ListTile(
          leading: SettingsIcon(icon: icon, danger: danger),
          title: Text(
            title,
            style: danger
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : null,
          ),
          subtitle: Text(
            stackStatus && status != null ? '$status · $subtitle' : subtitle,
          ),
          trailing: status == null || stackStatus ? null : Text(status!),
          enabled: false,
          minVerticalPadding: 12,
        );
      },
    ),
  );
}
