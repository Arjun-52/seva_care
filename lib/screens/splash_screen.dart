import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/dependency_injection.dart';
import '../core/storage/local_storage_service.dart';
import '../services/api_service.dart';
import '../utils/app_logger.dart';
import '../core/api/api_client.dart';
import '../models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // ─── Animation Controllers ────────────────
  late AnimationController _floatController;    // Floating background circles
  late AnimationController _logoController;     // Logo bounce-in
  late AnimationController _heartController;    // Heart beat pulse
  late AnimationController _glowController;     // Saffron glow ring expand
  late AnimationController _nameController;     // Brand name slide-in
  late AnimationController _taglineController;  // Tagline + bottom fade
  late AnimationController _shimmerController;  // Shimmer sweep

  // ─── Animations ───────────────────────────
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _heartScale;
  late Animation<double> _glowSize;
  late Animation<double> _glowOpacity;
  late Animation<Offset> _hindiSlide;     // "आप" from left
  late Animation<Offset> _engSlide;       // "no" from right
  late Animation<double> _nameOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _bottomOpacity;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initAnimations();
    _startSequence();
  }

  void _initControllers() {
    _floatController = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat();

    _logoController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    );

    _heartController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );

    _glowController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );

    _nameController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),
    );

    _taglineController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );

    _shimmerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  void _initAnimations() {
    // Logo — elastic bounce in
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.3, curve: Curves.easeIn)),
    );

    // Heart — double beat (scale up-down-up-down)
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
    ]).animate(_heartController);

    // Glow ring — expands outward and fades
    _glowSize = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOutCubic),
    );
    _glowOpacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _glowController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );

    // Brand name — "आप" slides from left, "no" slides from right
    _hindiSlide = Tween<Offset>(begin: const Offset(-1.5, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _nameController, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)),
    );
    _engSlide = Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _nameController, curve: const Interval(0.15, 0.7, curve: Curves.easeOutBack)),
    );
    _nameOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _nameController, curve: const Interval(0, 0.4, curve: Curves.easeIn)),
    );

    // Tagline — staggered fade-up
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _taglineController, curve: const Interval(0, 0.5, curve: Curves.easeIn)),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _taglineController, curve: const Interval(0, 0.5, curve: Curves.easeOutCubic)),
    );
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _taglineController, curve: const Interval(0.3, 0.7, curve: Curves.easeIn)),
    );
    _bottomOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _taglineController, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Phase 1: Logo bounces in
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Phase 2: Heart beats + glow ring expands
    _heartController.forward();
    _glowController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Phase 3: Brand name slides in from both sides
    _nameController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Phase 4: Tagline + subtitle + bottom decoration
    _taglineController.forward();

    // Phase 5: Wait then navigate
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final storage = locator<LocalStorageService>();
    final rememberMe = storage.getRememberMe();
    final isLoggedIn = storage.getIsLoggedIn();
    final token = storage.getAuthToken();
    final refreshToken = storage.getRefreshToken();
    final role = storage.getUserRole();

    if (rememberMe && isLoggedIn && token != null && refreshToken != null && role != null) {
      AppLogger.i('Restoring session for user. Role: $role');
      ApiService.setTokens(access: token, refresh: refreshToken);

      // Fetch fresh profile details from GET /v1/auth/me during session restoration
      AppLogger.i('Fetch profile started');
      try {
        final profileResult = await locator<ApiClient>().get('auth/me');
        if (profileResult.success && profileResult.data != null) {
          final profileUser = UserModel.fromJson(profileResult.data as Map<String, dynamic>);
          await storage.saveUserId(profileUser.id);
          await storage.saveUserName(profileUser.name);
          await storage.saveUserEmail(profileUser.email);
          await storage.saveUserRole(profileUser.role.isNotEmpty ? profileUser.role : role);
          await storage.saveUserPhone(profileUser.phone);
          await storage.saveUserAvatar(profileUser.avatar);
          await storage.saveUserCountry(profileUser.country);
          await storage.saveUserTimezone(profileUser.timezone);
          await storage.saveUserLanguage(profileUser.language);
          await storage.saveUserStatus(profileUser.status);
          AppLogger.i('Profile fetched successfully');
          AppLogger.i('Profile cache updated');
        } else {
          AppLogger.e('Profile fetch failed: ${profileResult.errorMessage}');
        }
      } catch (profileErr, profileStack) {
        AppLogger.e('Profile fetch failed', profileErr, profileStack);
      }
      
      String destRoute = '/onboarding';
      if (role == 'family') {
        destRoute = '/family';
      } else if (role == 'care_aide') {
        destRoute = '/aide';
      } else if (role == 'senior') {
        destRoute = '/senior';
      } else if (role == 'admin') {
        destRoute = '/admin';
      }

      AppLogger.i('Navigation target detected: $destRoute');
      if (mounted) {
        context.go(destRoute);
      }
    } else {
      AppLogger.i('No saved session found or rememberMe is disabled. Clearing session.');
      await storage.clearSession();
      if (mounted) {
        context.go('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _logoController.dispose();
    _heartController.dispose();
    _glowController.dispose();
    _nameController.dispose();
    _taglineController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AapnoColors.nightGradient),
        child: Stack(
          children: [
            // ─── Floating Background Circles ────────
            _buildFloatingCircles(size),

            // ─── Expanding Glow Ring ────────────────
            _buildGlowRing(size),

            // ─── Main Content ───────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── Animated Logo ────────────────
                  _buildLogo(),
                  const SizedBox(height: 36),

                  // ─── Brand Name (आपno) ────────────
                  _buildBrandName(),
                  const SizedBox(height: 16),

                  // ─── Tagline Pill ─────────────────
                  _buildTagline(),
                  const SizedBox(height: 12),

                  // ─── Subtitle ─────────────────────
                  _buildSubtitle(),
                ],
              ),
            ),

            // ─── Bottom Decoration ──────────────────
            _buildBottomDecoration(),
          ],
        ),
      ),
    );
  }

  // ─── Floating Background Circles ──────────────
  Widget _buildFloatingCircles(Size size) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (_, __) {
        final t = _floatController.value;
        return Stack(
          children: [
            // Top-right saffron circle — slow drift
            Positioned(
              top: -80 + math.sin(t * 2 * math.pi) * 12,
              right: -60 + math.cos(t * 2 * math.pi) * 8,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AapnoColors.saffron.withAlpha(20 + (math.sin(t * 2 * math.pi) * 8).round()),
                ),
              ),
            ),
            // Bottom-left teal circle
            Positioned(
              bottom: -100 + math.cos(t * 2 * math.pi + 1) * 15,
              left: -80 + math.sin(t * 2 * math.pi + 1) * 10,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AapnoColors.teal.withAlpha(15 + (math.cos(t * 2 * math.pi) * 6).round()),
                ),
              ),
            ),
            // Mid-left small saffron circle
            Positioned(
              top: 140 + math.sin(t * 2 * math.pi + 2) * 10,
              left: -30 + math.cos(t * 2 * math.pi + 2) * 6,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AapnoColors.saffron.withAlpha(12),
                ),
              ),
            ),
            // Right-mid navy circle
            Positioned(
              top: size.height * 0.6 + math.cos(t * 2 * math.pi + 3) * 8,
              right: -50 + math.sin(t * 2 * math.pi + 3) * 10,
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Expanding Saffron Glow Ring ──────────────
  Widget _buildGlowRing(Size size) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (_, __) {
        final ringSize = 120 + _glowSize.value * 200;
        return Center(
          child: Opacity(
            opacity: _glowOpacity.value,
            child: Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AapnoColors.saffron.withAlpha(100),
                  width: 2.5 - _glowSize.value * 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Animated Logo ────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _heartController, _shimmerController]),
      builder: (_, __) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: SizedBox(
              width: 130, height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow shadow
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: AapnoColors.saffron.withAlpha(60),
                          blurRadius: 50,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: AapnoColors.primary.withAlpha(40),
                          blurRadius: 80,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  // Main logo container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Saffron heart swoosh — with heartbeat
                          Transform.scale(
                            scale: _heartScale.value,
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 62,
                              color: AapnoColors.saffron.withAlpha(35),
                            ),
                          ),
                          // Logo text — आपno
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: 'आप',
                                style: GoogleFonts.poppins(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: AapnoColors.primary,
                                  height: 1.1,
                                ),
                              ),
                              TextSpan(
                                text: 'no',
                                style: GoogleFonts.poppins(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: AapnoColors.saffron,
                                  height: 1.1,
                                ),
                              ),
                            ]),
                          ),
                          // Shimmer sweep overlay
                          Positioned.fill(
                            child: _buildShimmer(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Shimmer Sweep ────────────────────────────
  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                Colors.white.withAlpha(40),
                Colors.transparent,
              ],
              stops: [
                (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                _shimmerController.value,
                (_shimmerController.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Container(color: Colors.white.withAlpha(1)),
        );
      },
    );
  }

  // ─── Brand Name (slides in from both sides) ───
  Widget _buildBrandName() {
    return AnimatedBuilder(
      animation: _nameController,
      builder: (_, __) {
        return Opacity(
          opacity: _nameOpacity.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // "आप" slides from left
              SlideTransition(
                position: _hindiSlide,
                child: Text(
                  'आप',
                  style: GoogleFonts.poppins(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                    height: 1,
                  ),
                ),
              ),
              // "no" slides from right
              SlideTransition(
                position: _engSlide,
                child: Text(
                  'no',
                  style: GoogleFonts.poppins(
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    color: AapnoColors.saffron,
                    letterSpacing: 1,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Tagline Pill ─────────────────────────────
  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _taglineController,
      builder: (_, __) {
        return SlideTransition(
          position: _taglineSlide,
          child: Opacity(
            opacity: _taglineOpacity.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AapnoColors.saffron.withAlpha(40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AapnoColors.saffron.withAlpha(180),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t('splash_tagline'),
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AapnoColors.saffronGlow,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AapnoColors.saffron.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Subtitle ─────────────────────────────────
  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _taglineController,
      builder: (_, __) {
        return Opacity(
          opacity: _subtitleOpacity.value,
          child: Text(
            t('app_subtitle'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white54,
              letterSpacing: 2,
            ),
          ),
        );
      },
    );
  }

  // ─── Bottom Decoration ────────────────────────
  Widget _buildBottomDecoration() {
    return Positioned(
      bottom: 48, left: 0, right: 0,
      child: AnimatedBuilder(
        animation: _taglineController,
        builder: (_, __) {
          return Opacity(
            opacity: _bottomOpacity.value,
            child: Column(
              children: [
                // Decorative line with saffron dot
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _decorLine(),
                    const SizedBox(width: 8),
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AapnoColors.saffron.withAlpha(120),
                        boxShadow: [
                          BoxShadow(
                            color: AapnoColors.saffron.withAlpha(40),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _decorLine(),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  t('app_tagline'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white30,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _decorLine() {
    return Container(
      width: 28, height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        gradient: LinearGradient(
          colors: [
            AapnoColors.saffron.withAlpha(0),
            AapnoColors.saffron.withAlpha(100),
          ],
        ),
      ),
    );
  }
}
