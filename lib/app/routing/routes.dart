abstract class Routes {
  const Routes._();

  // ── Entry ────────────────────────────────────────────────────────────────
  static const String splashScreen = '/';

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const String loginScreen = '/loginScreen';
  static const String registerScreen = '/registerScreen';
  static const String resetPasswordScreen = '/resetPasswordScreen';

  // ── M0 placeholder (يُستبدل في M1 بـ Gate + Retailer/Wholesaler Shells) ──
  static const String mainNavigationScreen = '/mainNavigationScreen';
}
