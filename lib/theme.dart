import 'package:flutter/material.dart';

class AppColors {
  static const Color bgBase = Color(0xFF07131F);
  static const Color bgPanel = Color(0xFF0D1B2A);
  static const Color bgPanelSoft = Color(0xFF1B263B);
  static const Color bgInput = Color(0x1AFFFFFF);
  
  static const Color accent = Color(0xFF56D8FF);
  static const Color accentDeep = Color(0xFF0077B6);
  static const Color accentGreen = Color(0xFF00B4D8);
  
  static const Color danger = Color(0xFFFF4D4D);
  static const Color borderStrong = Color(0xFF56D8FF);
  
  static const Color textMain = Color(0xFFEDF2F4);
  static const Color textSoft = Color(0xFF8D99AE);
  static const Color textDim = Color(0xFF415A77);
  
  static const List<Color> accentGradient = [Color(0xFF56D8FF), Color(0xFF1580C8)];
}

class AppStyles {
  static BoxDecoration glass({double opacity = 0.7, double radius = 20, Color? borderColor}) {
    return BoxDecoration(
      color: AppColors.bgPanel.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.1), 
        width: 1.2
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4), 
          blurRadius: 25, 
          offset: const Offset(0, 10)
        ),
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.05),
          blurRadius: 2,
          spreadRadius: -1,
        )
      ],
    );
  }

  static BoxDecoration neonBorder({bool active = false}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: active ? AppColors.accent : Colors.white.withValues(alpha: 0.05),
        width: 1.5,
      ),
      boxShadow: active ? [
        BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 1),
      ] : [],
    );
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgBase,
      fontFamily: 'Bahnschrift',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
        surface: AppColors.bgPanel,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInput,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: AppColors.accent, fontSize: 13),
      ),
    );
  }
}
