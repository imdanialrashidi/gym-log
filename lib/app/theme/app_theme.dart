import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';

/// Dark-only application theme built from [AppTokens].
abstract final class AppTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppTokens.accent,
      onPrimary: AppTokens.onAccent,
      secondary: AppTokens.info,
      onSecondary: AppTokens.background,
      error: AppTokens.danger,
      onError: AppTokens.background,
      surface: AppTokens.surface,
      onSurface: AppTokens.textPrimary,
      surfaceContainerLowest: AppTokens.background,
      surfaceContainerLow: AppTokens.surface,
      surfaceContainer: AppTokens.surface,
      surfaceContainerHigh: AppTokens.surface2,
      surfaceContainerHighest: AppTokens.surface2,
      surfaceDim: AppTokens.background,
      surfaceBright: AppTokens.surface2,
      onSurfaceVariant: AppTokens.textSecondary,
      outline: AppTokens.outline,
      outlineVariant: AppTokens.outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      fontFamily: AppTokens.fontFamily,
      scaffoldBackgroundColor: AppTokens.background,
      canvasColor: AppTokens.background,
      dividerColor: AppTokens.outline,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.background,
        foregroundColor: AppTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppTokens.surface,
        indicatorColor: AppTokens.accent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppTokens.onAccent : AppTokens.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppTokens.accent : AppTokens.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppTokens.textPrimary),
        bodyMedium: TextStyle(color: AppTokens.textPrimary),
        bodySmall: TextStyle(color: AppTokens.textSecondary),
        labelLarge: TextStyle(
          color: AppTokens.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(color: AppTokens.textSecondary),
        titleLarge: TextStyle(
          color: AppTokens.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppTokens.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: const IconThemeData(color: AppTokens.textPrimary),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AppTokens.onAccent
                : AppTokens.textPrimary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AppTokens.accent
                : AppTokens.surface;
          }),
          side: const WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: AppTokens.textSecondary),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
          ),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          ),
        ),
      ),
    );
  }
}
