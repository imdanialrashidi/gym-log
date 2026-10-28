import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';

/// Dark-only application theme built from [AppTokens].
///
/// Obsidian Telemetry raises hierarchy by surface luminance and 1 px structure,
/// never by shadow, blur, gradient, or hue. Every shape is a square, every
/// interactive control keeps a 48 dp target, and white is the only focal
/// signal. Component themes carry the visual hierarchy so feature widgets stay
/// declarative.
abstract final class AppTheme {
  /// Built once. ThemeData construction is not free, and the app is dark-only,
  /// so rebuilding it on every widget rebuild buys nothing.
  static final ThemeData dark = _buildDark();

  static ThemeData _buildDark() {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: AppTokens.accent,
      onPrimary: AppTokens.onAccent,
      secondary: AppTokens.info,
      onSecondary: AppTokens.onInfo,
      tertiary: AppTokens.weight,
      onTertiary: AppTokens.onInfo,
      error: AppTokens.danger,
      onError: AppTokens.onDanger,
      surface: AppTokens.surface,
      surfaceContainerLowest: AppTokens.background,
      surfaceContainerLow: AppTokens.surface,
      surfaceContainer: AppTokens.surface,
      surfaceContainerHigh: AppTokens.surface2,
      surfaceContainerHighest: AppTokens.surface3,
      surfaceDim: AppTokens.background,
      surfaceBright: AppTokens.surface3,
      onSurfaceVariant: AppTokens.textSecondary,
      outline: AppTokens.outline,
      outlineVariant: AppTokens.outline,
    );

    const TextTheme textTheme = TextTheme(
      displayLarge: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 56,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -2.0,
        fontFeatures: AppTokens.telemetryFeatures,
      ),
      displayMedium: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 44,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -1.6,
        fontFeatures: AppTokens.telemetryFeatures,
      ),
      displaySmall: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.08,
        letterSpacing: -1.2,
        fontFeatures: AppTokens.telemetryFeatures,
      ),
      headlineLarge: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.9,
        fontFeatures: AppTokens.telemetryFeatures,
      ),
      headlineMedium: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.16,
        letterSpacing: -0.6,
        fontFeatures: AppTokens.telemetryFeatures,
      ),
      headlineSmall: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.35,
        fontFeatures: AppTokens.telemetryFeatures,
      ),
      titleLarge: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.15,
      ),
      titleMedium: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        color: AppTokens.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      labelMedium: TextStyle(
        color: AppTokens.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        color: AppTokens.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.25,
        letterSpacing: 0.3,
      ),
    );

    const RoundedRectangleBorder squareShape = RoundedRectangleBorder();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      fontFamily: AppTokens.fontFamily,
      scaffoldBackgroundColor: AppTokens.background,
      canvasColor: AppTokens.background,
      dividerColor: AppTokens.outline,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.background,
        foregroundColor: AppTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleTextStyle: TextStyle(
          color: AppTokens.textPrimary,
          fontFamily: AppTokens.fontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.15,
        ),
        shape: Border(bottom: BorderSide(color: AppTokens.outline)),
      ),
      cardTheme: const CardThemeData(
        color: AppTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: squareShape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppTokens.surface,
        indicatorColor: AppTokens.accent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: squareShape,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppTokens.onAccent : AppTokens.textSecondary,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppTokens.textPrimary : AppTokens.textSecondary,
            fontFamily: AppTokens.fontFamily,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.disabled)) {
              return AppTokens.surface3;
            }
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFE4E4E7);
            }
            return AppTokens.accent;
          }),
          foregroundColor: const WidgetStatePropertyAll<Color>(
            AppTokens.onAccent,
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontFamily: AppTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 14),
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(squareShape),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(AppTokens.textPrimary),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontFamily: AppTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          minimumSize: WidgetStatePropertyAll<Size>(
            Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          ),
          padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 12),
          ),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: AppTokens.outlineStrong),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(squareShape),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(AppTokens.accent),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontFamily: AppTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          minimumSize: WidgetStatePropertyAll<Size>(
            Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(squareShape),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll<Size>(
            Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          ),
          iconSize: WidgetStatePropertyAll<double>(20),
          foregroundColor: WidgetStatePropertyAll<Color>(AppTokens.textPrimary),
          shape: WidgetStatePropertyAll<OutlinedBorder>(squareShape),
        ),
      ),
      iconTheme: const IconThemeData(color: AppTokens.textPrimary, size: 20),
      listTileTheme: const ListTileThemeData(
        iconColor: AppTokens.textSecondary,
        textColor: AppTokens.textPrimary,
        selectedColor: AppTokens.textPrimary,
        selectedTileColor: AppTokens.surface3,
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: AppTokens.space2,
          vertical: AppTokens.spaceHalf,
        ),
        shape: squareShape,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.background,
        labelStyle: TextStyle(color: AppTokens.textSecondary),
        floatingLabelStyle: TextStyle(
          color: AppTokens.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        hintStyle: TextStyle(color: AppTokens.textMuted),
        helperStyle: TextStyle(color: AppTokens.textMuted),
        errorStyle: TextStyle(
          color: AppTokens.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        suffixStyle: TextStyle(color: AppTokens.textMuted),
        counterStyle: TextStyle(color: AppTokens.textMuted),
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: AppTokens.space2,
          vertical: AppTokens.space1 + AppTokens.spaceHalf,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTokens.outlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTokens.outlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTokens.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTokens.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppTokens.danger, width: 2),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppTokens.surface2,
        selectedColor: AppTokens.accent,
        disabledColor: AppTokens.surface2,
        side: BorderSide(color: AppTokens.outlineStrong),
        labelStyle: TextStyle(
          color: AppTokens.textPrimary,
          fontFamily: AppTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: AppTokens.onAccent,
          fontFamily: AppTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: AppTokens.onAccent,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppTokens.space1 + AppTokens.spaceHalf,
          vertical: AppTokens.space1,
        ),
        shape: squareShape,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((
            Set<WidgetState> states,
          ) {
            return states.contains(WidgetState.selected)
                ? AppTokens.onAccent
                : AppTokens.textPrimary;
          }),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontFamily: AppTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((
            Set<WidgetState> states,
          ) {
            return states.contains(WidgetState.selected)
                ? AppTokens.accent
                : AppTokens.surface2;
          }),
          side: const WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: AppTokens.outlineStrong),
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(squareShape),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected)
              ? AppTokens.onAccent
              : AppTokens.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected)
              ? AppTokens.accent
              : AppTokens.surface3;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          return states.contains(WidgetState.selected)
              ? AppTokens.accent
              : AppTokens.outlineStrong;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTokens.accent,
        linearTrackColor: AppTokens.surface3,
        circularTrackColor: AppTokens.surface3,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppTokens.surface2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppTokens.outline),
        ),
        titleTextStyle: TextStyle(
          color: AppTokens.textPrimary,
          fontFamily: AppTokens.fontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.15,
        ),
        contentTextStyle: TextStyle(
          color: AppTokens.textSecondary,
          fontFamily: AppTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppTokens.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppTokens.surface,
        showDragHandle: false,
        shape: RoundedRectangleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTokens.surface4,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: AppTokens.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: squareShape,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppTokens.surface2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppTokens.outline),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: AppTokens.surface3,
          borderRadius: BorderRadius.zero,
          border: Border.fromBorderSide(
            BorderSide(color: AppTokens.outlineStrong),
          ),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: AppTokens.textPrimary),
        waitDuration: const Duration(milliseconds: 500),
      ),
      dividerTheme: const DividerThemeData(
        color: AppTokens.outline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
