import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/seva_widgets.dart';
import '../auth/login_screen.dart';
import 'medicine_reminder_screen.dart';
import 'contacts_screen.dart';
import '../../core/storage/local_storage_service.dart';
import '../../services/dependency_injection.dart';
import '../../services/api_service.dart';
import '../../utils/app_logger.dart';
import '../../core/api/api_client.dart';

class SeniorHome extends StatelessWidget {
  const SeniorHome({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return t('good_morning');
    if (hour < 17) return t('good_afternoon');
    return t('good_evening');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Greeting
            Row(children: [
              const SevaAvatar(initials: 'KD', size: 56, bgColor: SevaColors.primary),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_greeting()}, Kamla Ji', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
                Text(t('heres_update'), style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
              ]),
            ]),
            const SizedBox(height: 28),

            // Giant SOS Button
            GestureDetector(
              onTap: () => _showSOS(context),
              child: Container(
                width: double.infinity, height: 160,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: SevaColors.red.withAlpha(89), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.emergency, color: Colors.white, size: 56),
                  const SizedBox(height: 10),
                  Text(t('sos_button'), style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                  Text(t('tap_for_emergency'), style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                ]),
              ),
            ),
            const SizedBox(height: 28),

            // Large Action Buttons
            Text(t('quick_actions'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.1,
              children: [
                _bigAction(context, Icons.phone, t('call_care_aide'), SevaColors.green, SevaColors.greenLight, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Row(children: [
                      Icon(Icons.phone_in_talk, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Calling Priya Meena...'),
                    ]),
                    behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
                  ));
                }),
                _bigAction(context, Icons.videocam, t('video_call_family'), SevaColors.primary, SevaColors.primaryLight, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Row(children: [
                      Icon(Icons.videocam, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Connecting to Rajesh...'),
                    ]),
                    behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.primary,
                  ));
                }),
                _bigAction(context, Icons.medication, t('medicine_reminder'), SevaColors.purple, SevaColors.purpleLight, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineReminderScreen()));
                }),
                _bigAction(context, Icons.people, t('my_contacts'), SevaColors.orange, SevaColors.orangeLight, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
                }),
              ],
            ),
            const SizedBox(height: 28),

            // Today's Schedule
            Text(t('todays_schedule'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
            const SizedBox(height: 12),
            ...[
              _scheduleItem('08:00 AM', t('morning_medicines'), Icons.medication, true),
              _scheduleItem('09:30 AM', t('hygiene'), Icons.water_drop, true),
              _scheduleItem('12:00 PM', t('therapy'), Icons.sports_gymnastics, true),
              _scheduleItem('01:00 PM', t('afternoon_medicines'), Icons.medication, false),
              _scheduleItem('05:00 PM', t('monitoring'), Icons.visibility, false),
              _scheduleItem('07:00 PM', t('evening_medicines'), Icons.medication, false),
            ],
            const SizedBox(height: 28),

            // Vitals
            Text(t('vitals'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _healthCard(t('blood_pressure'), '130/82', t('normal'), SevaColors.primary, SevaColors.primaryLight)),
              const SizedBox(width: 12),
              Expanded(child: _healthCard(t('oxygen_level'), '96%', t('normal'), SevaColors.green, SevaColors.greenLight)),
            ]),
            const SizedBox(height: 20),

            // Sign Out
            Center(child: TextButton.icon(
              onPressed: () => _showSignOut(context),
              icon: const Icon(Icons.logout, size: 18, color: SevaColors.textTertiary),
              label: Text(t('sign_out'), style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textTertiary)),
            )),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Widget _bigAction(BuildContext context, IconData icon, String label, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SevaColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, size: 30, color: color)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label, textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.textPrimary, height: 1.3)),
          ),
        ]),
      ),
    );
  }

  Widget _scheduleItem(String time, String activity, IconData icon, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SevaColors.border)),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(
              color: done ? SevaColors.greenLight : SevaColors.divider,
              borderRadius: BorderRadius.circular(12)),
            child: Icon(done ? Icons.check_circle : icon, size: 22,
              color: done ? SevaColors.green : SevaColors.textTertiary)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(activity, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500,
              color: done ? SevaColors.textSecondary : SevaColors.textPrimary,
              decoration: done ? TextDecoration.lineThrough : null)),
            Text(time, style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textTertiary)),
          ])),
          if (done) const Icon(Icons.check_circle, color: SevaColors.green, size: 22),
        ]),
      ),
    );
  }

  Widget _healthCard(String label, String value, String status, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SevaColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: SevaColors.textPrimary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
          child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ),
      ]),
    );
  }

  void _showSOS(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.emergency, color: SevaColors.red, size: 32),
        const SizedBox(width: 10),
        Text(t('emergency'), style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800)),
      ]),
      content: Text(t('sos_confirm'),
        style: GoogleFonts.inter(fontSize: 15, color: SevaColors.textSecondary, height: 1.5)),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(t('aide_dispatched'))),
              ]),
              behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.red,
              duration: const Duration(seconds: 5),
            ));
          },
          style: ElevatedButton.styleFrom(backgroundColor: SevaColors.red, minimumSize: const Size(double.infinity, 48)),
          child: Text(t('ok'), style: const TextStyle(fontSize: 16)),
        ),
      ],
    ));
  }

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
}
