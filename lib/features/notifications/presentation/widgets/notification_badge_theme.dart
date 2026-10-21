import 'package:flutter/material.dart';

/// Theme values supplied by AppTheme; no color literals in feature widgets.
class NotificationBadgeTheme extends ThemeExtension<NotificationBadgeTheme> {
  const NotificationBadgeTheme({
    required this.socialBackground,
    required this.socialForeground,
    required this.reminderBackground,
    required this.reminderForeground,
    required this.unreadBackground,
  });

  final Color socialBackground;
  final Color socialForeground;
  final Color reminderBackground;
  final Color reminderForeground;
  final Color unreadBackground;

  @override
  NotificationBadgeTheme copyWith({
    Color? socialBackground,
    Color? socialForeground,
    Color? reminderBackground,
    Color? reminderForeground,
    Color? unreadBackground,
  }) => NotificationBadgeTheme(
    socialBackground: socialBackground ?? this.socialBackground,
    socialForeground: socialForeground ?? this.socialForeground,
    reminderBackground: reminderBackground ?? this.reminderBackground,
    reminderForeground: reminderForeground ?? this.reminderForeground,
    unreadBackground: unreadBackground ?? this.unreadBackground,
  );

  @override
  NotificationBadgeTheme lerp(NotificationBadgeTheme? other, double t) {
    if (other == null) return this;
    return NotificationBadgeTheme(
      socialBackground: Color.lerp(
        socialBackground,
        other.socialBackground,
        t,
      )!,
      socialForeground: Color.lerp(
        socialForeground,
        other.socialForeground,
        t,
      )!,
      reminderBackground: Color.lerp(
        reminderBackground,
        other.reminderBackground,
        t,
      )!,
      reminderForeground: Color.lerp(
        reminderForeground,
        other.reminderForeground,
        t,
      )!,
      unreadBackground: Color.lerp(
        unreadBackground,
        other.unreadBackground,
        t,
      )!,
    );
  }
}
