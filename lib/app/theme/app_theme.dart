import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';

/// Dark-only application theme built from [AppTokens].
///
/// Component themes carry the visual hierarchy so feature widgets stay
/// declarative: surfaces are raised by color and a hairline border rather than
/// by shadows, and every interactive control keeps at least a 48 dp target.
abstract final class AppTheme {
  /// Built once. ThemeData construction is not free, and the app is dark-only,
  /// so rebuilding it on every widget rebuild buys nothing.
  static final ThemeData dark = _buildDark();

  static ThemeData _buildDark() {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: AppTokens.accent,
      onPrimary: AppTokens.onAccent,
      secondary: AppTokens.info,
      onSecondary: AppTokens.background,
      tertiary: AppTokens.weight,
      onTertiary: AppTokens.background,
      error: AppTokens.danger,
      onError: AppTokens.background,
      surface: AppTokens.surface,
      onSurface: AppTokens.textPrimary,
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
      displaySmall: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 38,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.8,
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
      ),
      headlineMedium: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
      ),
      headlineSmall: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.2,
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
      ),
      titleLarge: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
      titleSmall: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
      bodyMedium: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: AppTokens.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        color: AppTokens.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        color: AppTokens.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        color: AppTokens.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: 0.3,
      ),
    );

    const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusLarge)),
    );
    const RoundedRectangleBorder controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMedium)),
    );

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
        titleTextStyle: TextStyle(
          color: AppTokens.textPrimary,
          fontFamily: AppTokens.fontFamily,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppTokens.surface,
        indicatorColor: AppTokens.accent.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusPill)),
        ),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppTokens.accent : AppTokens.textSecondary,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppTokens.accent : AppTokens.textSecondary,
            fontFamily: AppTokens.fontFamily,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(AppTokens.accent),
          foregroundColor: WidgetStatePropertyAll<Color>(AppTokens.onAccent),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontFamily: AppTokens.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          minimumSize: WidgetStatePropertyAll<Size>(
            Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          ),
          padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsetsDirectional.symmetric(horizontal: 22, vertical: 14),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(controlShape),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(AppTokens.textPrimary),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontFamily: AppTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          minimumSize: WidgetStatePropertyAll<Size>(
            Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          ),
          padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsetsDirectional.symmetric(horizontal: 18, vertical: 12),
          ),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: AppTokens.outline, width: 1.2),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(controlShape),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(AppTokens.accent),
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
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppTokens.radiusSmall),
              ),
            ),
          ),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll<Size>(
            Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
          ),
          iconSize: WidgetStatePropertyAll<double>(22),
          foregroundColor: WidgetStatePropertyAll<Color>(AppTokens.textPrimary),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppTokens.radiusSmall),
              ),
            ),
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppTokens.textPrimary, size: 22),
      listTileTheme: const ListTileThemeData(
        iconColor: AppTokens.textSecondary,
        textColor: AppTokens.textPrimary,
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: AppTokens.space2,
          vertical: AppTokens.spaceHalf,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppTokens.radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface2,
        labelStyle: const TextStyle(color: AppTokens.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppTokens.accent),
        hintStyle: const TextStyle(color: AppTokens.textSecondary),
        helperStyle: const TextStyle(color: AppTokens.textSecondary),
        suffixStyle: const TextStyle(color: AppTokens.textSecondary),
        counterStyle: const TextStyle(color: AppTokens.textSecondary),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppTokens.space2,
          vertical: AppTokens.space1 + AppTokens.spaceHalf,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.danger, width: 2),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppTokens.surface2,
        selectedColor: AppTokens.accent,
        disabledColor: AppTokens.surface2,
        side: BorderSide(color: AppTokens.outline),
        labelStyle: TextStyle(
          color: AppTokens.textPrimary,
          fontFamily: AppTokens.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: AppTokens.onAccent,
          fontFamily: AppTokens.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: AppTokens.onAccent,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppTokens.space1 + AppTokens.spaceHalf,
          vertical: AppTokens.space1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusPill)),
        ),
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected)
              ? AppTokens.onAccent
              : AppTokens.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.selected)
              ? AppTokens.accent
              : AppTokens.surface3;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTokens.accent,
        linearTrackColor: AppTokens.surface3,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppTokens.surface2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppTokens.radiusLarge),
          ),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppTokens.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppTokens.surface,
        showDragHandle: true,
        dragHandleColor: AppTokens.outline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.vertical(
            top: Radius.circular(AppTokens.radiusLarge),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTokens.surface3,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: AppTokens.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppTokens.surface2,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppTokens.surface3,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(color: AppTokens.outline),
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
