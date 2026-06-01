import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  List<_OnboardingPage> get _pages => [
    _OnboardingPage(
      icon: Icons.favorite,
      iconBg: SevaColors.saffronLight,
      iconColor: SevaColors.saffron,
      gradient: SevaColors.saffronGradient,
      title: t('onboarding_1_title'),
      subtitle: t('onboarding_1_desc'),
    ),
    _OnboardingPage(
      icon: Icons.monitor_heart,
      iconBg: SevaColors.primaryLight,
      iconColor: SevaColors.primary,
      gradient: SevaColors.peacockGradient,
      title: t('onboarding_2_title'),
      subtitle: t('onboarding_2_desc'),
    ),
    _OnboardingPage(
      icon: Icons.family_restroom,
      iconBg: SevaColors.greenLight,
      iconColor: SevaColors.green,
      gradient: SevaColors.sevaGradient,
      title: t('onboarding_3_title'),
      subtitle: t('onboarding_3_desc'),
    ),
  ];

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          // Top bar with skip and logo
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 20, right: 16),
            child: Row(children: [
              // Mini logo
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: SevaColors.saffronGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(child: Text('S',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              const SizedBox(width: 8),
              Text(t('app_name'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
              const Spacer(),
              TextButton(
                onPressed: _goToLogin,
                child: Text(t('skip'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.textTertiary)),
              ),
            ]),
          ),

          // Page content
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                final page = _pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // Gradient icon container
                    Container(
                      width: 130, height: 130,
                      decoration: BoxDecoration(
                        gradient: page.gradient,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [BoxShadow(
                          color: page.iconColor.withAlpha(40),
                          blurRadius: 30, offset: const Offset(0, 12))],
                      ),
                      child: Icon(page.icon, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 48),
                    Text(page.title, textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: SevaColors.textPrimary, height: 1.2)),
                    const SizedBox(height: 20),
                    Text(page.subtitle, textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 15, color: SevaColors.textSecondary, height: 1.6)),
                  ]),
                );
              },
            ),
          ),

          // Bottom section
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Column(children: [
              // Dots
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(
                _pages.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _current == i ? 28 : 8, height: 8,
                  decoration: BoxDecoration(
                    gradient: _current == i ? SevaColors.saffronGradient : null,
                    color: _current == i ? null : SevaColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )),
              const SizedBox(height: 32),

              // Button
              SizedBox(
                width: double.infinity, height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: SevaColors.sevaGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: SevaColors.primary.withAlpha(76), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_current == _pages.length - 1 ? t('get_started') : t('next'),
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color iconBg, iconColor;
  final LinearGradient gradient;
  final String title, subtitle;

  _OnboardingPage({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.gradient, required this.title, required this.subtitle,
  });
}
