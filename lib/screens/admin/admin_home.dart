import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/seva_widgets.dart';
import '../auth/login_screen.dart';
import '../../services/dependency_injection.dart';
import '../../core/storage/local_storage_service.dart';
import '../../services/api_service.dart';
import '../../utils/app_logger.dart';
import '../../core/api/api_client.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  void _showSignOut(BuildContext context) {
    bool loading = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('${t('sign_out')}?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            content: loading
                ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(color: SevaColors.primary),
                    ),
                  )
                : Text(t('sign_out_confirm'), style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
            actions: loading
                ? []
                : [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() => loading = true);
                        AppLogger.i('Logout initiated');
                        
                        final storage = locator<LocalStorageService>();
                        
                        try {
                          AppLogger.i('Logout API called');
                          final result = await locator<ApiClient>().post('auth/logout');
                          
                          if (result.success) {
                            AppLogger.i('Logout successful');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Logged out successfully'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: SevaColors.green,
                              ));
                            }
                          } else {
                            AppLogger.e('Logout API failed: ${result.errorMessage}');
                          }
                        } catch (e, stack) {
                          AppLogger.e('Logout API failed with error', e, stack);
                        } finally {
                          AppLogger.i('Forced local logout executed, clearing session');
                          await storage.clearSession();
                          ApiService.clearTokens();
                          AppLogger.i('Local session cleared');
                          
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          
                          AppLogger.i('Navigation to login');
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: SevaColors.red),
                      child: Text(t('sign_out')),
                    ),
                  ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageService = locator<LocalStorageService>();
    final adminName = storageService.getUserName() ?? 'Admin';
    final adminEmail = storageService.getUserEmail() ?? 'admin@seva.org.in';
    final adminAvatar = storageService.getUserAvatar() ?? 'AD';

    return Scaffold(
      backgroundColor: SevaColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  SevaAvatar(initials: adminAvatar, size: 56, bgColor: SevaColors.primary),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $adminName',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: SevaColors.textPrimary,
                        ),
                      ),
                      Text(
                        adminEmail,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: SevaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // SOS Warning / Alert Panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SevaColors.primary, SevaColors.orange],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: SevaColors.primary.withAlpha(50),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'System Status',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All Seva Services running normally. 0 critical alerts active.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Admin Quick Actions
              Text(
                'Quick Controls',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SevaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.2,
                children: [
                  _statCard('Total Seniors', '124', Icons.people_outline, SevaColors.green),
                  _statCard('Active Aides', '32', Icons.badge_outlined, SevaColors.primary),
                  _statCard('Total Visits', '1,450', Icons.analytics_outlined, SevaColors.purple),
                  _statCard('Feedback Score', '4.9', Icons.star_border, SevaColors.amber),
                ],
              ),
              const SizedBox(height: 32),

              // Sign Out
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _showSignOut(context),
                  icon: const Icon(Icons.logout, color: SevaColors.red, size: 20),
                  label: Text(
                    t('sign_out'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SevaColors.red,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: SevaColors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SevaColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: SevaColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SevaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
