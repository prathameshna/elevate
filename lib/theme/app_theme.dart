import 'package:flutter/material.dart';

class ElevateTheme {
  static const _primaryBg = Color(0xFF0F0F0F);
  static const _secondaryBg = Color(0xFF1F1F1F);
  static const accent = Color(0xFF4FACFE);
  static const primaryAccent = Color(0xFF0A9FFF);
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFA0A0A0);
  static const cardBorder = Color(0xFF3A3A3A);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const quick = Color(0xFF14B8A6);

  static ThemeData darkTheme(BuildContext context) {
    const base = ColorScheme.dark(
      primary: accent,
      secondary: accent,
      surface: _secondaryBg,
      onSurface: textPrimary,
    );

    return ThemeData(
      colorScheme: base,
      scaffoldBackgroundColor: _primaryBg,
      useMaterial3: true,
      textTheme: _textTheme(Theme.of(context).textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _primaryBg,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: _secondaryBg,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : Colors.grey.shade400,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent.withValues(alpha: 0.35)
              : Colors.grey.shade700,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: textPrimary,
        shape: CircleBorder(),
        elevation: 8,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: textPrimary,
      ),
      displayMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: textPrimary,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: textPrimary,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textPrimary,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textSecondary,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textSecondary,
      ),
    );
  }
}

