import 'package:flutter/material.dart';

class AppColors {
  static const maroon = Color(0xFF254A45);
  static const maroonDark = Color(0xFF1B3733);
  static const cream = Color(0xFFFAF8F4);
  static const cardBg = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E0DA);
  static const text = Color(0xFF1A1412);
  static const muted = Color(0xFF7A726A);
  static const warningBg = Color(0xFFFFF8E1);
  static const warningBorder = Color(0xFFFFE08A);

 static const bohra = Color(0xFF254A45);      // --bohra
  static const sunni = Color(0xFF1E8449);      // --sunni  (was wrongly blue)
  static const shia = Color(0xFF922B73);       // --shia   (was wrongly purple)
  static const christian = Color(0xFF2B6CB0);  // --christian
  static const french = Color(0xFF2D2D2D);     // --french (was wrongly gray-blue)
  static const jewish = Color(0xFF7C3AED);     // --jewish
  static const hindu = Color(0xFFD9822B);      // --hindu  (was wrongly orange-red)
  static const parsi = Color(0xFF16A085);      // --parsi
  static const personal = Color(0xFF1F9D55);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.maroon,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.maroon,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.maroon.withValues(alpha: .12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          color: selected ? AppColors.maroon : AppColors.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.maroon : AppColors.muted,
        );
      }),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
      bodyMedium: TextStyle(color: AppColors.muted, fontSize: 13),
    ),
  );
}

class InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class LocationWarningBanner extends StatelessWidget {
  final String locationName;

  const LocationWarningBanner({super.key, required this.locationName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        border: Border.all(color: AppColors.warningBorder),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 12.5, color: AppColors.text),
          children: [
            const TextSpan(text: 'Using '),
            TextSpan(
              text: locationName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const TextSpan(text: '. Set your location for accurate timings.'),
          ],
        ),
      ),
    );
  }
}

Color parseHexColor(String? value, {Color fallback = AppColors.maroon}) {
  if (value == null || value.trim().isEmpty) return fallback;
  try {
    var hex = value.trim().replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  } catch (_) {
    return fallback;
  }
}
