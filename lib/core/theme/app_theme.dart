import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static final PageTransitionsTheme _webPageTransitionsTheme =
      PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const FadeForwardsPageTransitionsBuilder(),
        },
      );

  static ThemeData material(Brightness brightness) {
    final scheme = _withNeutralSurfaces(
      ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),
    );
    final modalSurface = brightness == Brightness.dark
        ? AppColors.modalSurfaceOnDark
        : AppColors.modalSurface;
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      pageTransitionsTheme: kIsWeb ? _webPageTransitionsTheme : null,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: modalSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppRadius.card),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }

  static ColorScheme _withNeutralSurfaces(ColorScheme scheme) {
    final grey = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: scheme.brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    );
    return scheme.copyWith(
      surface: grey.surface,
      surfaceDim: grey.surfaceDim,
      surfaceBright: grey.surfaceBright,
      surfaceContainerLowest: grey.surfaceContainerLowest,
      surfaceContainerLow: grey.surfaceContainerLow,
      surfaceContainer: grey.surfaceContainer,
      surfaceContainerHigh: grey.surfaceContainerHigh,
      surfaceContainerHighest: grey.surfaceContainerHighest,
      onSurface: grey.onSurface,
      onSurfaceVariant: grey.onSurfaceVariant,
      outline: grey.outline,
      outlineVariant: grey.outlineVariant,
      inverseSurface: grey.inverseSurface,
      onInverseSurface: grey.onInverseSurface,
    );
  }

  static CupertinoThemeData cupertino(Brightness brightness) {
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: AppColors.seed,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? CupertinoColors.systemBackground.darkColor
          : CupertinoColors.systemGroupedBackground.color,
    );
  }
}
