import 'package:flutter/material.dart';

/// Colors are supplied exclusively by AppTheme.
class ProfilePalette extends ThemeExtension<ProfilePalette> {
  const ProfilePalette({
    required this.gold,
    required this.goldSoft,
    required this.goldInk,
    required this.lockedBackground,
    required this.lockedInk,
  });
  final Color gold;
  final Color goldSoft;
  final Color goldInk;
  final Color lockedBackground;
  final Color lockedInk;

  @override
  ProfilePalette copyWith({
    Color? gold,
    Color? goldSoft,
    Color? goldInk,
    Color? lockedBackground,
    Color? lockedInk,
  }) => ProfilePalette(
    gold: gold ?? this.gold,
    goldSoft: goldSoft ?? this.goldSoft,
    goldInk: goldInk ?? this.goldInk,
    lockedBackground: lockedBackground ?? this.lockedBackground,
    lockedInk: lockedInk ?? this.lockedInk,
  );

  @override
  ProfilePalette lerp(covariant ProfilePalette? other, double t) {
    if (other == null) return this;
    return ProfilePalette(
      gold: Color.lerp(gold, other.gold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      goldInk: Color.lerp(goldInk, other.goldInk, t)!,
      lockedBackground: Color.lerp(
        lockedBackground,
        other.lockedBackground,
        t,
      )!,
      lockedInk: Color.lerp(lockedInk, other.lockedInk, t)!,
    );
  }
}
