// lib/theme.dart
//
// Colors and text styles pulled directly from your HTML templates
// (widget_today.html's --maroon: #254a45 / --maroon-dark: #1b3733,
// and the cream/beige card backgrounds used across calendar.html,
// events.html, prayer.html). Keep this as the single source of truth
// so every screen stays visually consistent with the web app.

import 'package:flutter/material.dart';

class AppColors {
  static const maroon = Color(0xFF254A45);
  static const maroonDark = Color(0xFF1B3733);
  static const cream = Color(0xFFFAF8F4);
  static const cardBg = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E0DA);
  static const text = Color(0xFF1A1412);
  static const muted = Color(0xFF7A726A);
  static const noteWarnBg = Color(0xFFFFF8E1);
  static const noteWarnBorder = Color(0xFFFFE08A);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.maroon,
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.maroon,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cardBg,
      indicatorColor: AppColors.maroon.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.maroon : AppColors.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? AppColors.maroon : AppColors.muted);
      }),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
      bodyMedium: TextStyle(color: AppColors.muted, fontSize: 13),
    ),
  );
}

/// Reusable card wrapper matching .stat-box / .saint-card / .timeline-wrap
/// from prayer.html -- fafafa-ish bg, thin border, rounded corners.
class InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const InfoCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

/// The yellow "using default location" banner from prayer.html/qibla.html.
class LocationWarningBanner extends StatelessWidget {
  final String locationName;
  const LocationWarningBanner({super.key, required this.locationName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.noteWarnBg,
        border: Border.all(color: AppColors.noteWarnBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 13, color: AppColors.text),
          children: [
            const TextSpan(text: 'These times are for '),
            TextSpan(text: locationName, style: const TextStyle(fontWeight: FontWeight.w700)),
            const TextSpan(text: ' (default) — set your location in Settings for accurate times.'),
          ],
        ),
      ),
    );
  }
}
