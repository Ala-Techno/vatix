import 'package:flutter/material.dart';

/// نظام الألوان لتطبيق Vatix — تصميم B2B حديث واحترافي مستند إلى Material 3
class AppColors {
  // منع الإنشاء
  const AppColors._();

  // ── Brand Colors (ألوان الهوية B2B الكحلية / السليت) ──────────────────────
  /// اللون الأساسي — كحلي غامق وقور (Deep Slate Navy)
  static const Color primary = Color(0xFF0F2942);

  /// الدرجة الأفتح من الأساسي
  static const Color primaryLight = Color(0xFF1E4976);

  /// الدرجة الداكنة
  static const Color primaryDark = Color(0xFF0A1B2C);

  /// لون النص والأيقونات على الأساسي
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// اللون الثانوي — تيل أعمال خفيف (Business Teal)
  static const Color secondary = Color(0xFF0D9488);
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// لون تمييز ثانوي (Accent Sky)
  static const Color accent = Color(0xFF0284C7);

  // ── Backgrounds & Surfaces (الخلفيات والأسطح) ──────────────────────────────
  /// خلفية التطبيق العامة — رمادي سحابي مريح للعين (Slate 50)
  static const Color background = Color(0xFFF8FAFC);

  /// أسطح البطاقات والحوارات — أبيض ناصع
  static const Color surface = Color(0xFFFFFFFF);

  /// سطح ثانوي مميز (حقول الإدخال، الحاويات) — Slate 100
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  /// لون الخط الفاصل
  static const Color divider = Color(0xFFE2E8F0);

  /// لون الحدود الخارجية
  static const Color border = Color(0xFFCBD5E1);

  /// لون حدود خفيفة
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // ── Status Colors (حالات النظام والأعمال) ──────────────────────────────────
  /// حالة نشط / مفعّل / معتمد (Active / Approved)
  static const Color statusActive = Color(0xFF16A34A);
  static const Color statusActiveBg = Color(0xFFDCFCE7);

  /// حالة قيد المراجعة / معلق (Pending)
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusPendingBg = Color(0xFFFEF3C7);

  /// حالة موقوف / مرفوض / حظر (Blocked / Rejected)
  static const Color statusBlocked = Color(0xFFDC2626);
  static const Color statusBlockedBg = Color(0xFFFEE2E2);

  // ── Feedback (التنبيهات) ───────────────────────────────────────────────────
  /// خطأ
  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);

  /// نجاح
  static const Color success = Color(0xFF16A34A);

  /// تحذير
  static const Color warning = Color(0xFFD97706);

  // ── Typography (ألوان النصوص) ─────────────────────────────────────────────
  /// نص أساسي بارز — Slate 900
  static const Color textPrimary = Color(0xFF0F172A);

  /// نص ثانوي وتوضيحي — Slate 500
  static const Color textSecondary = Color(0xFF64748B);

  /// نص باهت وتلميحات (Hints) — Slate 400
  static const Color textHint = Color(0xFF94A3B8);

  // ── Shimmer & Shadows (التأثيرات الحركية والظلال) ──────────────────────────
  /// لون أساسي للـ Shimmer
  static const Color shimmerBase = Color(0xFFE2E8F0);

  /// لون وميض الـ Shimmer
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

  /// ظل ناعم للبطاقات (Subtle Ambient Shadow)
  static const Color shadowColor = Color(0x0F0F172A);
}
