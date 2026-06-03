import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/local_storage_service.dart';
import '../../models/user_model.dart';
import '../../services/dependency_injection.dart';
import '../../services/api_service.dart';
import '../../utils/app_logger.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscure = true;
  bool _loading = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final nameVal = _nameController.text.trim();
    final emailVal = _emailController.text.trim();
    final phoneVal = _phoneController.text.trim();
    final passwordVal = _passwordController.text;

    // ─── Validation ───────────────────────────
    if (nameVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name is required.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (nameVal.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name must be at least 2 characters long.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (emailVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Email is required.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailVal)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid email address.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (phoneVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Phone number is required.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final phoneRegex = RegExp(r'^\+?[0-9]{10,13}$');
    if (!phoneRegex.hasMatch(phoneVal)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid phone number (minimum 10 digits).'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (passwordVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password is required.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (passwordVal.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password must be at least 6 characters long.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _loading = true);
    AppLogger.i('Registration started for name: $nameVal, email: $emailVal, phone: $phoneVal');

    try {
      final result = await locator<ApiClient>().post('auth/register', body: {
        'name': nameVal,
        'email': emailVal,
        'phone': phoneVal,
        'password': passwordVal,
      });

      if (!mounted) return;

      if (result.success && result.data != null) {
        AppLogger.i('Registration success');

        final loginResponse = LoginResponse.fromJson(result.data as Map<String, dynamic>);
        final userRole = loginResponse.user.role.isNotEmpty ? loginResponse.user.role : 'family';
        
        AppLogger.i('User saved and role detected: $userRole');

        // Store tokens & user details securely
        final storage = locator<LocalStorageService>();
        await storage.saveAuthToken(loginResponse.token);
        await storage.saveRefreshToken(loginResponse.refreshToken);
        await storage.saveUserId(loginResponse.user.id);
        await storage.saveUserName(loginResponse.user.name);
        await storage.saveUserEmail(loginResponse.user.email);
        await storage.saveUserRole(userRole);
        await storage.saveUserPhone(loginResponse.user.phone);
        await storage.saveUserAvatar(loginResponse.user.avatar);
        await storage.saveRememberMe(true); // Automatically set rememberMe as true for seamless sign-ups
        await storage.saveIsLoggedIn(true);

        // Also set tokens in ApiService
        ApiService.setTokens(access: loginResponse.token, refresh: loginResponse.refreshToken);
        AppLogger.i('Token saved successfully');

        // Show Success Feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Success'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: SevaColors.green,
          ));
        }

        String destRoute;
        if (userRole == 'family') {
          destRoute = '/family';
        } else if (userRole == 'care_aide') {
          destRoute = '/aide';
        } else if (userRole == 'senior') {
          destRoute = '/senior';
        } else if (userRole == 'admin') {
          destRoute = '/admin';
        } else {
          destRoute = '/family';
        }

        AppLogger.i('Navigation target: $destRoute');
        if (mounted) {
          context.go(destRoute);
        }
      } else {
        final errorMsg = result.errorMessage;
        AppLogger.e('Registration failed: $errorMsg');

        String displayError = 'Something went wrong. Please try again.';
        if (result.failure != null) {
          final failStr = result.failure.toString();
          if (failStr.contains('NetworkFailure') || failStr.contains('SocketException') || failStr.contains('TimeoutException')) {
            displayError = 'Unable to connect. Please check internet connection.';
          } else {
            displayError = errorMsg;
          }
        } else {
          displayError = errorMsg;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(displayError),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e, stack) {
      AppLogger.e('Unknown error during registration', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Top bar: Logo + Title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(gradient: SevaColors.saffronGradient, borderRadius: BorderRadius.circular(14)),
                    child: Center(
                      child: Text(
                        'S',
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('app_name'), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: SevaColors.textPrimary)),
                      Text(t('app_subtitle'), style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Title
              Text(
                'Create Account',
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: SevaColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign up to start your 14-day free trial',
                style: GoogleFonts.inter(fontSize: 15, color: SevaColors.textSecondary),
              ),
              const SizedBox(height: 28),

              // Name
              Text(
                'Full Name',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person_outline, color: SevaColors.textTertiary, size: 20),
                ),
              ),
              const SizedBox(height: 18),

              // Email
              Text(
                t('email'),
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'john@example.com',
                  prefixIcon: Icon(Icons.email_outlined, color: SevaColors.textTertiary, size: 20),
                ),
              ),
              const SizedBox(height: 18),

              // Phone
              Text(
                t('phone'),
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '9876543210',
                  prefixIcon: Icon(Icons.phone_outlined, color: SevaColors.textTertiary, size: 20),
                ),
              ),
              const SizedBox(height: 18),

              // Password
              Text(
                t('password'),
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textPrimary),
              ),
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
              const SizedBox(height: 30),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: SevaColors.sevaGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: SevaColors.primary.withAlpha(76), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                    ),
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sign Up',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign In Link
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Already have an account? ', style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
                        TextSpan(text: 'Sign In', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.primary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
