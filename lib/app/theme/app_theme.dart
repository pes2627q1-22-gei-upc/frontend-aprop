import 'package:flutter/material.dart';

import '../../features/notifications/presentation/widgets/notification_badge_theme.dart';

class AppTheme {
  AppTheme._();

  static const forest = Color(0xFF143C32);
  static const coral = Color(0xFFEF674F);
  static const cream = Color(0xFFF6EFE2);

  static const cardBackground = Color(0xFFFFFCF8);
  static const ink = Color(0xFF10232D);
  static const muted = Color(0xFF667078);
  static const border = Color(0xFFE3DED5);
  static const selectedBackground = Color(0xFFE6EEE7);

  /// Crema verdós, una mica més fosc que el fons, per a l'acció destacada
  /// d'Inici («Crear activitat»).
  static const sage = Color(0xFFD6DCBC);

  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    extensions: const [
      NotificationBadgeTheme(
        socialBackground: Color(0xFFFFF1CC),
        socialForeground: Color(0xFF785400),
        reminderBackground: Color(0xFFE1EFF8),
        reminderForeground: Color(0xFF205B83),
        unreadBackground: selectedBackground,
      ),
    ],
    colorScheme: ColorScheme.fromSeed(
      seedColor: forest,
      primary: forest,
      onPrimary: cream,
      secondary: coral,
      onSecondary: ink,
      surface: cardBackground,
      onSurface: ink,
      onSurfaceVariant: muted,
      outlineVariant: border,
    ),
    appBarTheme: const AppBarThemeData(
      backgroundColor: cream,
      foregroundColor: forest,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: sage,
      foregroundColor: forest,
      // Més petit que el per defecte (56) perquè no tapi tant les targetes.
      // L'àrea tàctil continua sent de 48 com a mínim.
      extendedSizeConstraints: BoxConstraints.tightFor(height: 44),
      extendedPadding: EdgeInsets.symmetric(horizontal: 16),
      extendedIconLabelSpacing: 8,
      extendedTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: cream,
      indicatorColor: selectedBackground,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? forest
              : cardBackground;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return ink.withValues(alpha: 0.38);
          }
          return states.contains(WidgetState.selected) ? cream : ink;
        }),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
    ),
  );
}

//Centralización de los colores y el tema de la aplicación para mantener consistencia en el diseño y facilitar cambios futuros.
//Este archivo centraliza la apariencia. Así podremos cambiar los colores de toda la app desde un único lugar.
