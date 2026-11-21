import 'package:flutter/material.dart';

import '../../models/user_summary.dart';

/// A person in a list (search results, friends): photo or initials, name and
/// `@username`. Tapping it opens their profile.
class UserRow extends StatelessWidget {
  const UserRow({
    super.key,
    required this.user,
    required this.onTap,
    this.trailing,
  });

  final UserSummary user;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final words = user.displayName.trim().split(RegExp(r'\s+'));
    final initials = words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
    final fallback = Center(child: Text(initials));
    final Widget picture;
    if (user.avatarAsset case final asset?) {
      picture = Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (user.avatarUrl case final url?) {
      picture = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else {
      picture = fallback;
    }
    return Semantics(
      button: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: 48,
                    child: ClipOval(
                      child: ColoredBox(
                        color: colors.secondaryContainer,
                        child: picture,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '@${user.username}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ?? const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
