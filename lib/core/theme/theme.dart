import 'package:flutter/material.dart';

/// Design tokens — dark-first premium UI (CRED/Uber-adjacent).
abstract final class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E1E2E);
  static const Color card = Color(0xFF1C1C28);

  static const Color purple = Color(0xFF6D28D9);
  static const Color blue = Color(0xFF2563EB);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentOrange = Color(0xFFF97316);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);

  static const Color outlineSubtle = Color(0x14FFFFFF);
}

abstract final class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.purple, AppColors.blue],
  );

  /// Subtle rim for cards / chrome.
  static LinearGradient get cardBorder => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.purple.withOpacity(0.35),
          AppColors.blue.withOpacity(0.22),
          AppColors.purple.withOpacity(0.18),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  static LinearGradient statTint(Color accent) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withOpacity(0.14),
          AppColors.card,
        ],
      );

  static LinearGradient get chartLine => const LinearGradient(
        colors: [AppColors.purple, AppColors.blue],
      );
}

abstract final class AppShadows {
  static List<BoxShadow> cardSoft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.32),
      blurRadius: 12,
      offset: const Offset(0, 5),
    ),
    BoxShadow(
      color: AppColors.purple.withOpacity(0.06),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  /// Slightly lifted — tap feedback baseline.
  static List<BoxShadow> cardRaised = [
    BoxShadow(
      color: Colors.black.withOpacity(0.38),
      blurRadius: 16,
      offset: const Offset(0, 7),
    ),
    BoxShadow(
      color: AppColors.blue.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> fabGlow = [
    BoxShadow(
      color: AppColors.purple.withOpacity(0.42),
      blurRadius: 22,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.blue.withOpacity(0.32),
      blurRadius: 18,
      offset: const Offset(0, 4),
    ),
  ];

  /// Extra layer for pulsing FAB (multiplied by pulse 0–1 in widget).
  static List<BoxShadow> fabGlowPulseLayer(double pulse) {
    final p = pulse.clamp(0.0, 1.0);
    return [
      BoxShadow(
        color: AppColors.purple.withOpacity(0.14 * p),
        blurRadius: 26 + 14 * p,
        spreadRadius: 1.5 * p,
        offset: Offset(0, 6 + 4 * p),
      ),
      BoxShadow(
        color: AppColors.blue.withOpacity(0.10 * p),
        blurRadius: 20 + 10 * p,
        spreadRadius: 0.5 * p,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> buttonSoft = [
    BoxShadow(
      color: AppColors.purple.withOpacity(0.18),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Spacing aligned with design spec.
abstract final class AppLayout {
  static const double padH = 16;
  static const double sectionGap = 24;
  static const double elementGap = 12;
  static const double radiusCard = 20;
  static const double radiusChip = 14;
  static const double cardBorderWidth = 1;
}

abstract final class AppMotion {
  static const Duration pageTransition = Duration(milliseconds: 275);
  static const Duration pressScale = Duration(milliseconds: 200);
  /// Release uses [SpringPressSurface] (easeOutBack) — keep this in the 200–400ms band.
  static const Duration pressRelease = Duration(milliseconds: 360);
  static const Curve pressCurve = Curves.easeOutCubic;
}

abstract final class AppTypography {
  static TextTheme darkTextTheme(TextTheme base) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: AppColors.textSecondary),
      bodyMedium: base.bodyMedium?.copyWith(color: AppColors.textSecondary),
      bodySmall: base.bodySmall?.copyWith(color: AppColors.textSecondary),
      labelLarge: base.labelLarge?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.labelMedium?.copyWith(color: AppColors.textSecondary),
      labelSmall: base.labelSmall?.copyWith(color: AppColors.textSecondary),
    );
  }
}
