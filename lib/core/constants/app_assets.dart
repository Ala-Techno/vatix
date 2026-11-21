/// Centralized repository for all asset paths used in the application.
abstract class AppAssets {
  // Private constructor to prevent instantiation.
  const AppAssets._();

  // ── Base Paths ──────────────────────────────────────────────────────────
  static const String _imagesPath = 'assets/images';
  // static const String _svgsPath = 'assets/svgs'; // If we use SVGs later

  // ── Images ──────────────────────────────────────────────────────────────
  static const String appLogo = '$_imagesPath/app_logo.png';
  static const String onboardingHeader = '$_imagesPath/onboarding_header.png';
  static const String placeholder = '$_imagesPath/placeholder.png';
  static const String banner = '$_imagesPath/banner_offers.jpg';
  static const String banner2 = '$_imagesPath/banner_offers_2.jpg';
  static const String splash = '$_imagesPath/splash_logo.png';

  // ── Icons / SVGs (if any) ────────────────────────────────────────────────
  // static const String icGoogle = '$_svgsPath/ic_google.svg';
}
