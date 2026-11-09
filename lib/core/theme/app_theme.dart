import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// تكوين سمة التطبيق (Theme) — Material 3 مصمم لتطبيقات الأعمال B2B
class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    const fontFamily = 'Cairo';

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,

      // ── لوحة الألوان (Color Scheme) ─────────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        error: AppColors.error,
        onError: AppColors.onError,
        outline: AppColors.border,
        outlineVariant: AppColors.borderSubtle,
        shadow: AppColors.shadowColor,
      ),

      // ── خلفية الشاشات (Scaffold) ───────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.background,

      // ── شريط التطبيق العلوي (AppBar) ───────────────────────────────────────
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        shadowColor: AppColors.shadowColor,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ── الأزرار الأساسية (Elevated Button) ─────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textHint,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── الأزرار المحددة (Outlined Button) ───────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textHint,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── الأزرار النصية (Text Button) ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── حقول الإدخال (Input Decoration) ────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textHint,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.primaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AppColors.error,
          fontSize: 12,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      // ── البطاقات (Card Theme) ──────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.shadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── الفواصل (Divider Theme) ────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── شريط التبويبات (TabBar Theme) ──────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.divider,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── رسائل التنبيه العائمة (SnackBar Theme) ──────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: Colors.white,
        ),
      ),

      // ── صناديق الحوار (Dialog Theme) ───────────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),

      // ── الرقاقات (Chip Theme) ──────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
