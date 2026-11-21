import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:vatix/app/routing/routes.dart';
import 'package:vatix/core/constants/app_assets.dart';
import 'package:vatix/features/auth/presentation/gate/auth_gate.dart';

/// [SplashScreen] — Custom splash screen for Vatix.
/// Designed for zero visual jump and seamless match with Native Splash.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _logoScaleAnim;
  late final Animation<double> _logoFadeAnim;
  late final Animation<double> _titleFadeAnim;
  late final Animation<Offset> _titleSlideAnim;
  late final Animation<double> _subtitleFadeAnim;

  // Actual navy box ratio within image file (1056px out of 2048px)
  static const double _badgeRatio = 1056.0 / 2048.0;
  // Frame width factor to match box width on native splash screen
  static const double _splashWidthFactor = 0.785;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache image in render cache immediately
    precacheImage(const AssetImage(AppAssets.splash), context).then((_) {
      // Remove native splash only after image is decompressed in memory
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    });
  }

  @override
  void initState() {
    super.initState();

    // ─── Animation setup for text and logo ───
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Premium animation: smooth zoom-in / pop effect for logo
    _logoScaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Initial soft fade-in for logo
    _logoFadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Fade and slide-up animation for "Vatix" title (0.0 -> 0.7)
    _titleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _titleSlideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Staggered fade in for subtitle (0.4 -> 1.0)
    _subtitleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 350ms delay before starting animation to allow native splash transition
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _animController.forward();
    });

    // ─── 3. Smooth transition to gate upon animation completion ───
    _initAppAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initAppAndNavigate() async {
    // Sufficient duration for logo and text animation (3200ms)
    await Future.delayed(const Duration(milliseconds: 3200));

    if (!mounted) return;

    // Ensure native splash is removed
    FlutterNativeSplash.remove();

    try {
      Navigator.of(context).pushReplacementNamed(Routes.gate);
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Calculate logo size to match native splash box dimensions
    final double logoBoxSize = screenWidth * _splashWidthFactor;

    // Actual badge radius inside image file excluding transparent margins
    final double actualBadgeRadius = (logoBoxSize * _badgeRatio) / 2;

    // Exact bottom edge of centered badge
    final double actualBadgeBottom = (screenHeight / 2) + actualBadgeRadius;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF7F9FC),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC), // Identical to native splash
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ─── 1. Logo with zoom/fade animation ───
            Center(
              child: FadeTransition(
                opacity: _logoFadeAnim,
                child: ScaleTransition(
                  scale: _logoScaleAnim,
                  child: SizedBox(
                    width: logoBoxSize,
                    height: logoBoxSize,
                    child: Image.asset(
                      AppAssets.splash,
                      width: logoBoxSize,
                      height: logoBoxSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // ─── 2. Text positioned below actual badge ───
            Positioned(
              top: actualBadgeBottom + 24,
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vatix title: Fade + Slide up animation
                  FadeTransition(
                    opacity: _titleFadeAnim,
                    child: SlideTransition(
                      position: _titleSlideAnim,
                      child: const Text(
                        'Vatix',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F2A4A),
                          letterSpacing: 1.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle: Staggered Fade In
                  FadeTransition(
                    opacity: _subtitleFadeAnim,
                    child: const Text(
                      'شبكة التوزيع المباشر بين المورد وتجاره',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
