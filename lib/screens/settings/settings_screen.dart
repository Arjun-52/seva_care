import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/seva_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _smsAlerts = true;
  bool _emailReports = true;
  final bool _emergencyAlerts = true;
  bool _dailySummary = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(title: Text(t('settings'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Notification Settings
          Text(t('notifications'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SevaCard(padding: EdgeInsets.zero, child: Column(children: [
            _toggleItem(Icons.notifications_active, t('push_notifications'), '',
              _pushNotifications, (v) => setState(() => _pushNotifications = v)),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _toggleItem(Icons.sms, t('sms_alerts'), '',
              _smsAlerts, (v) => setState(() => _smsAlerts = v)),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _toggleItem(Icons.email, t('email_reports'), '',
              _emailReports, (v) => setState(() => _emailReports = v)),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _toggleItem(Icons.emergency, t('emergency_alerts'), '',
              _emergencyAlerts, null),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _toggleItem(Icons.summarize, t('daily_summary'), '',
              _dailySummary, (v) => setState(() => _dailySummary = v)),
          ])),
          const SizedBox(height: 24),

          // Language
          Text(t('language'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SevaCard(padding: EdgeInsets.zero, child: Column(children: [
            _selectItem(Icons.language, t('choose_language'), SevaLocalizations.currentLanguage.nativeName, () => _showLanguagePicker()),
          ])),
          const SizedBox(height: 24),

          // Privacy & Security
          Text(t('privacy_security'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SevaCard(padding: EdgeInsets.zero, child: Column(children: [
            _navItem(Icons.lock, t('change_password'), () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Password change link sent to your email.'),
                behavior: SnackBarBehavior.floating,
              ));
            }),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _navItem(Icons.fingerprint, t('biometric_login'), () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(t('biometric_login')),
                behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
              ));
            }),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _navItem(Icons.security, t('two_factor'), () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(t('two_factor')),
                behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
              ));
            }),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _navItem(Icons.download, t('download_data'), () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Data export request submitted.'),
                behavior: SnackBarBehavior.floating,
              ));
            }),
          ])),
          const SizedBox(height: 24),

          // About
          Text(t('about'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SevaCard(padding: EdgeInsets.zero, child: Column(children: [
            _infoItem(Icons.info_outline, t('version'), '1.0.0'),
            const Divider(height: 1, color: SevaColors.divider, indent: 52),
            _navItem(Icons.gavel, t('dpdp_act'), () {
              _showDPDPInfo();
            }),
          ])),
          const SizedBox(height: 24),

          // Danger zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: SevaColors.redLight, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SevaColors.red.withAlpha(76))),
            child: Row(children: [
              const Icon(Icons.delete_forever, color: SevaColors.red),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('delete_account'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.red)),
              ])),
              TextButton(
                onPressed: () {
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text('${t('delete_account')}?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    content: Text(t('sign_out_confirm'),
                      style: GoogleFonts.inter(color: SevaColors.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('cancel'))),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(backgroundColor: SevaColors.red),
                        child: Text(t('confirm')),
                      ),
                    ],
                  ));
                },
                child: Text(t('confirm'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: SevaColors.red)),
              ),
            ]),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _toggleItem(IconData icon, String label, String subtitle, bool value, void Function(bool)? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Icon(icon, size: 22, color: SevaColors.textSecondary),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500))),
        Switch(value: value, onChanged: onChanged, activeTrackColor: SevaColors.primary),
      ]),
    );
  }

  Widget _selectItem(IconData icon, String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 22, color: SevaColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500))),
          Text(value, style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textTertiary)),
          if (onTap != null) const SizedBox(width: 4),
          if (onTap != null) const Icon(Icons.chevron_right, size: 20, color: SevaColors.textTertiary),
        ]),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 22, color: SevaColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right, size: 20, color: SevaColors.textTertiary),
        ]),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 22, color: SevaColors.textSecondary),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500))),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textTertiary)),
      ]),
    );
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
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                title: Text(lang.nativeName, style: GoogleFonts.inter(
                  fontWeight: SevaLocalizations.currentLocale == lang.code ? FontWeight.w700 : FontWeight.w400,
                  color: SevaLocalizations.currentLocale == lang.code ? SevaColors.primary : SevaColors.textPrimary,
                )),
                subtitle: Text(lang.name, style: GoogleFonts.inter(fontSize: 12, color: SevaColors.textTertiary)),
                trailing: SevaLocalizations.currentLocale == lang.code
                  ? const Icon(Icons.check_circle, color: SevaColors.primary) : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: SevaLocalizations.currentLocale == lang.code ? SevaColors.primarySoft : null,
                onTap: () {
                  SevaLocalizations.setLocale(lang.code);
                  Navigator.pop(context);
                  setState(() {}); // Rebuild settings screen
                },
              ),
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  void _showDPDPInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.verified_user, color: SevaColors.green),
          const SizedBox(width: 10),
          Text(t('dpdp_act'), style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          'Seva Senior Care is fully compliant with the Digital Personal Data Protection (DPDP) Act, 2023.\n\n'
          'Your rights:\n'
          '- Right to access your data\n'
          '- Right to correct inaccurate data\n'
          '- Right to erase your data\n'
          '- Right to nominate\n\n'
          'All data is encrypted with AES-256 and stored securely within India.',
          style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('ok')),
          ),
        ],
      ),
    );
  }
}
