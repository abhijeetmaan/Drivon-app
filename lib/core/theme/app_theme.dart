import 'package:flutter/material.dart';

import 'theme.dart';

class AppTheme {
  static ThemeData light() => _base(brightness: Brightness.light);
  static ThemeData dark() => _base(brightness: Brightness.dark);

  static ThemeData _base({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      brightness: brightness,
      primary: AppColors.purple,
      secondary: AppColors.blue,
    ).copyWith(
      surface: isDark ? AppColors.surface : const Color(0xFFF8FAFC),
      onSurface: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
      onSurfaceVariant: isDark ? AppColors.textSecondary : const Color(0xFF64748B),
      surfaceVariant: isDark ? AppColors.card : const Color(0xFFE2E8F0),
      outline: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
      outlineVariant: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? Colors.transparent : const Color(0xFFF1F5F9),
    );

    final textTheme = isDark
        ? AppTypography.darkTextTheme(base.textTheme)
        : base.textTheme.copyWith(
            headlineSmall: base.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.25,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.background : scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: isDark ? AppColors.surface : scheme.surface,
        indicatorColor: AppColors.purple.withOpacity(isDark ? 0.22 : 0.14),
        labelTextStyle: MaterialStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(MaterialState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: states.contains(MaterialState.selected) ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(MaterialState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: isDark ? AppColors.card : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusCard)),
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.card.withOpacity(0.85) : scheme.surfaceVariant.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: _FadeSlidePageTransitionsBuilder(),
        },
      ),
      splashColor: AppColors.purple.withOpacity(0.12),
      highlightColor: AppColors.purple.withOpacity(0.06),
    );
  }
}

class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.024),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.988, end: 1.0).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
