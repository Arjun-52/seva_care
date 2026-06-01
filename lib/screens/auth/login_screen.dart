import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedRole = 0;
  bool _obscure = true;
  bool _loading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  List<String> get _roles => [t('family'), t('care_aide'), t('senior')];

  @override
  void initState() {
    super.initState();
    _updateHints();
  }

  void _updateHints() {
    _emailController.text = '';
    _passwordController.text = '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);

    String destRoute;
    if (_selectedRole == 0) {
      destRoute = '/family';
    } else if (_selectedRole == 1) {
      destRoute = '/aide';
    } else {
      destRoute = '/senior';
    }

    if (!mounted) return;
    context.go(destRoute);
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: SevaColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(t('choose_language'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          for (var lang in SevaLocalizations.supportedLanguages)
            ListTile(
              leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
              title: Text(lang.nativeName, style: GoogleFonts.inter(
                fontWeight: SevaLocalizations.currentLocale == lang.code ? FontWeight.w700 : FontWeight.w400)),
              subtitle: Text(lang.name, style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textTertiary)),
              trailing: SevaLocalizations.currentLocale == lang.code
                ? const Icon(Icons.check_circle, color: SevaColors.primary) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: SevaLocalizations.currentLocale == lang.code ? SevaColors.primarySoft : null,
              onTap: () {
                SevaLocalizations.setLocale(lang.code);
                Navigator.pop(context);
                setState(() {}); // Rebuild login screen
              },
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),

            // Top bar: Logo + Language
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(gradient: SevaColors.saffronGradient, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text('S',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('app_name'), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: SevaColors.textPrimary)),
                Text(t('app_subtitle'), style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
              ]),
              const Spacer(),
              // Language Button
              GestureDetector(
                onTap: _showLanguagePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: SevaColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SevaColors.primaryLight),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(SevaLocalizations.currentLanguage.flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(SevaLocalizations.currentLanguage.nativeName,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: SevaColors.primary)),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 16, color: SevaColors.primary),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 36),

            // Welcome
            Text(t('welcome_back'), style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: SevaColors.textPrimary)),
            const SizedBox(height: 6),
            Text(t('sign_in_continue'), style: GoogleFonts.inter(fontSize: 15, color: SevaColors.textSecondary)),
            const SizedBox(height: 28),

            // Sign in as label
            Text(t('sign_in_as'), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textSecondary)),
            const SizedBox(height: 10),

            // Role Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: SevaColors.divider, borderRadius: BorderRadius.circular(14)),
              child: Row(children: List.generate(3, (i) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedRole = i;
                    _updateHints();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedRole == i ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _selectedRole == i
                          ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Text(_roles[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: _selectedRole == i ? SevaColors.primary : SevaColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ))),
            ),
            const SizedBox(height: 28),

            // Email/Phone
            Text(_selectedRole == 2 ? t('phone') : t('email'),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: _selectedRole == 0 ? 'rajesh@email.com' : _selectedRole == 1 ? 'aide@seva.org.in' : '+91 94XXX XXXXX',
                prefixIcon: Icon(_selectedRole == 2 ? Icons.phone_outlined : Icons.email_outlined, color: SevaColors.textTertiary, size: 20),
              ),
            ),
            const SizedBox(height: 18),

            // Password
            Text(t('password'), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: '${t('password')}...',
                prefixIcon: const Icon(Icons.lock_outline, color: SevaColors.textTertiary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: SevaColors.textTertiary, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Password reset link sent to your email.'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                child: Text(t('forgot_password'),
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.primary)),
              ),
            ),
            const SizedBox(height: 20),

            // Sign In Button
            SizedBox(
              width: double.infinity, height: 52,
              child: Container(
                decoration: BoxDecoration(gradient: SevaColors.sevaGradient, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: SevaColors.primary.withAlpha(76), blurRadius: 12, offset: const Offset(0, 4))]),
                child: ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent),
                  child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${t('sign_in')} ${_roles[_selectedRole]}',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ]),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_selectedRole == 0)
              Center(child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t('start_free_trial')),
                    behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.primary,
                  ));
                },
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${t('no_account')} ', style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
                  TextSpan(text: t('start_free_trial'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.primary)),
                ])),
              )),

            const SizedBox(height: 32),
            Center(child: Column(children: [
              Text(t('encrypted'), style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textTertiary)),
              const SizedBox(height: 4),
              Text(t('dpdp_act'), style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textTertiary)),
            ])),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}
